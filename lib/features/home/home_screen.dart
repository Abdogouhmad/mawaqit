import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/const/app_constants.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/ui/widgets/empty_state.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/home/widgets/alarm_access_gate.dart';
import 'package:mawaqit/features/home/widgets/countdown_hero.dart';
import 'package:mawaqit/features/home/widgets/prayer_schedule_tile.dart';
import 'package:mawaqit/features/home/widgets/solar_card.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_loading_state.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The Home tab.
///
/// Layout, not logic: the controller resolves the day and the alarm pipeline;
/// this screen only composes it. The per-second clock is read by [_LiveCountdown]
/// and [_SunsetFooter], never here, so a tick repaints those leaves instead of
/// the prayer timeline and solar card.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onOpenTimes, this.onOpenSettings});

  /// Supplied by the shell so this feature does not import the router back.
  final VoidCallback? onOpenTimes;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeControllerProvider);
    final state = asyncState.value;
    final locationMissing =
        asyncState.hasError || (state != null && state.day == null);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeControllerProvider),
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.huge,
              AppSpacing.xs,
              AppSpacing.huge,
              AppSpacing.pageBottom,
            ),
            children: [
              _HomeHeader(
                locationMissing: locationMissing,
                onOpenTimes: onOpenTimes,
                onOpenSettings: onOpenSettings,
              ),
              asyncState.when(
                // Keep the current day on screen while a refresh or a settings
                // change recomputes it; a pull-to-refresh is already visible.
                skipLoadingOnReload: true,
                loading: () => const AppLoadingState(),
                error: (error, _) => _HomeError(
                  message: error.toString(),
                  onOpenSettings: onOpenSettings,
                ),
                data: (data) => _HomeBody(state: data),
              ),
              // Mounted only once home data exists: that is where notification
              // initialisation has finished and the system-access read is real.
              if (state != null) const AlarmAccessGate(),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.tera),
                _DevAdhanPreview(
                  prayer: state?.nextPrayer?.kind ?? PrayerKind.maghrib,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.locationMissing,
    this.onOpenTimes,
    this.onOpenSettings,
  });

  final bool locationMissing;
  final VoidCallback? onOpenTimes;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: AppIconSize.xxl,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          const Flexible(
            child: UiText(
              AppConstants.appName,
              type: UiTextType.titleLarge,
              fontWeight: AppWeight.bold,
              letterSpacing: AppTypeDetail.appTitleTracking,
            ),
          ),
          if (locationMissing) ...[
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              label: l10n.homeLocationUnavailable,
              button: true,
              excludeSemantics: true,
              child: AppIconButton(
                key: const Key('location-missing-indicator'),
                icon: Icons.location_off_outlined,
                tooltip: l10n.homeLocationUnavailable,
                color: scheme.error,
                onPressed: onOpenSettings,
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            label: l10n.navTimes,
            button: true,
            excludeSemantics: true,
            child: AppIconButton(
              icon: Icons.calendar_month_outlined,
              tooltip: l10n.navTimes,
              onPressed: onOpenTimes,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final day = state.day;
    final mutedIds = ref.watch(mutedPrayersProvider).value ?? const <String>{};

    if (day == null) {
      return _HomeError(message: state.error ?? l10n.homeErrorBody);
    }

    final now = state.now;
    final next = state.nextPrayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        _DateLine(now: now, locationName: state.locationName, scheme: scheme),
        const SizedBox(height: AppSpacing.block),
        _LiveCountdown(nextPrayer: next, currentPrayer: state.currentPrayer),
        const SizedBox(height: AppSpacing.emphasis),
        SectionHeader(
          label: l10n.homeDailySchedule,
          trailing: UiText(
            day.methodName,
            type: UiTextType.labelSmall,
            color: scheme.onSurfaceVariant,
            letterSpacing: AppTypeDetail.actionLetterSpacing,
            fontWeight: AppWeight.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PrayerTimeline(
          prayers: day.prayers,
          now: now,
          next: next,
          mutedIds: mutedIds,
          date: day.date,
          onToggleMute: (prayer) => ref
              .read(mutedPrayersProvider.notifier)
              .toggle(NotificationService.prayerIdFor(day.date, prayer.kind)),
        ),
        const SizedBox(height: AppSpacing.xl),
        SolarCard(day: day),
        const SizedBox(height: AppSpacing.xxxl),
        _SunsetFooter(methodLabel: state.methodLabel, sunset: day.sunset),
        const SizedBox(height: AppSpacing.huge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: AppIconSize.xs,
              color: scheme.onSurfaceVariant.withValues(
                alpha: AppOpacity.secondaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // `Flexible` is load-bearing: a bare Text in a Row gets unbounded
            // width and paints past the card at 200% text in every locale.
            Flexible(
              child: UiText(
                l10n.homePrivacyNote,
                type: UiTextType.labelSmall,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.secondaryText,
                ),
                letterSpacing: AppTypeDetail.actionLetterSpacing,
                fontWeight: AppWeight.medium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.now,
    required this.locationName,
    required this.scheme,
  });

  final DateTime now;
  final String locationName;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    const metaStyle = TextStyle(letterSpacing: AppTypeDetail.overlineTracking);

    return Column(
      children: [
        UiText(
          TimeFormatter.gregorian(now),
          textAlign: TextAlign.center,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: UiText(
                TimeFormatter.hijri(now).toUpperCase(),
                type: UiTextType.labelSmall,
                style: metaStyle,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.secondaryText,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: AppSpacing.xxs,
              height: AppSpacing.xxs,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.faintMark,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: UiText(
                locationName,
                type: UiTextType.labelSmall,
                style: metaStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrayerTimeline extends StatelessWidget {
  const _PrayerTimeline({
    required this.prayers,
    required this.now,
    required this.next,
    required this.mutedIds,
    required this.date,
    required this.onToggleMute,
  });

  final List<PrayerTime> prayers;
  final DateTime now;
  final PrayerTime? next;
  final Set<String> mutedIds;
  final DateTime date;
  final ValueChanged<PrayerTime> onToggleMute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < prayers.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppStroke.hairline,
                indent: AppSpacing.xxxl + AppSpacing.touch + AppSpacing.lg,
                endIndent: AppSpacing.xxxl,
                color: scheme.outlineVariant.withValues(
                  alpha: AppOpacity.hairline,
                ),
              ),
            PrayerScheduleTile(
              prayer: prayers[i],
              status: _statusFor(prayers[i], now, next),
              muted: mutedIds.contains(
                NotificationService.prayerIdFor(date, prayers[i].kind),
              ),
              onToggleMute: () => onToggleMute(prayers[i]),
              isLast: i == prayers.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

/// Rebuilds only the countdown, once a second.
///
/// [HomeState] is emitted on prayer boundaries; the second hand lives here so
/// the date line, prayer list and solar card are not rebuilt sixty times a
/// minute for a string only this hero shows.
class _LiveCountdown extends ConsumerWidget {
  const _LiveCountdown({required this.nextPrayer, required this.currentPrayer});

  final PrayerTime? nextPrayer;
  final PrayerTime? currentPrayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = nextPrayer;
    if (next == null) {
      return const CountdownHero(
        nextPrayer: null,
        currentPrayer: null,
        nextIn: Duration.zero,
        progress: 0,
      );
    }

    final now = ref.watch(homeClockProvider).value ?? DateTime.now();
    final start = currentPrayer?.time ?? DateTime(now.year, now.month, now.day);
    final total = next.time.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    final remaining = next.time.difference(now);

    return CountdownHero(
      nextPrayer: next,
      currentPrayer: currentPrayer,
      nextIn: remaining.isNegative ? Duration.zero : remaining,
      progress: total <= 0 ? 0 : (elapsed / total).clamp(0.0, 1.0),
    );
  }
}

/// Method label and sunset countdown. Ticks with the same shared clock as
/// [_LiveCountdown] rather than forcing a whole-body rebuild.
class _SunsetFooter extends ConsumerWidget {
  const _SunsetFooter({required this.methodLabel, required this.sunset});

  final String methodLabel;
  final DateTime sunset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(homeClockProvider).value ?? DateTime.now();
    final sunsetIn = sunset.difference(now);
    final style = TextStyle(
      letterSpacing: AppTypeDetail.footerTracking,
      color: scheme.onSurfaceVariant.withValues(
        alpha: AppOpacity.secondaryText,
      ),
    );

    return Row(
      children: [
        // Both labels are Flexible: the countdown grows through the day and an
        // Expanded sibling would squeeze it out of the row entirely.
        Flexible(
          child: UiText(
            methodLabel.toUpperCase(),
            type: UiTextType.labelSmall,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.wb_twilight, size: AppIconSize.sm, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: UiText(
            (sunsetIn.isNegative
                    ? l10n.homeSunsetAt(TimeFormatter.clock(sunset))
                    : l10n.homeSunsetIn(TimeFormatter.longCountdown(sunsetIn)))
                .toUpperCase(),
            type: UiTextType.labelSmall,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

PrayerTileStatus _statusFor(PrayerTime prayer, DateTime now, PrayerTime? next) {
  if (prayer.time.isAfter(now)) {
    if (next != null && next.kind == prayer.kind && next.time == prayer.time) {
      return PrayerTileStatus.active;
    }
    return PrayerTileStatus.upcoming;
  }
  return PrayerTileStatus.passed;
}

/// Debug-only harness for the full-screen adhan presenter.
class _DevAdhanPreview extends ConsumerWidget {
  const _DevAdhanPreview({required this.prayer});

  final PrayerKind prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = prayer.localized(l10n);

    return AppCard(
      ambient: false,
      color: scheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: AppIconSize.md,
                color: scheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: UiText(
                  l10n.homeDevOnly,
                  type: UiTextType.labelSmall,
                  color: scheme.tertiary,
                  letterSpacing: AppTypeDetail.sectionLetterSpacing,
                  fontWeight: AppWeight.semibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.homePreviewAdhan(title),
            icon: Icons.notifications_active_outlined,
            variant: AppButtonVariant.outlined,
            expanded: false,
            onPressed: () async {
              final service = ref.read(notificationServiceProvider);
              await service.init();
              service.showAdhanOverlay(title: title);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          UiText(
            l10n.homeDevPreviewBody,
            type: UiTextType.labelSmall,
            textAlign: TextAlign.center,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, this.onOpenSettings});

  final String message;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.offsetLg),
      child: AppCard(
        color: scheme.errorContainer,
        borderColor: scheme.error.withValues(alpha: AppOpacity.hairline),
        ambient: false,
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.homeErrorTitle,
          body: message,
          action: onOpenSettings == null
              ? null
              : AppButton(
                  label: l10n.navSettings,
                  icon: Icons.settings_outlined,
                  onPressed: onOpenSettings,
                ),
        ),
      ),
    );
  }
}
