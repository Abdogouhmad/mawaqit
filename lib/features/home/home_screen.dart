import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/home/widgets/alarm_access_gate.dart';
import 'package:mawaqit/features/home/widgets/countdown_hero.dart';
import 'package:mawaqit/features/home/widgets/prayer_schedule_tile.dart';
import 'package:mawaqit/features/home/widgets/solar_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.huge,
              AppSpacing.xs,
              AppSpacing.huge,
              AppSpacing.pageBottom,
            ),
            children: [
              _HomeHeader(locationMissing: locationMissing),
              asyncState.when(
                loading: () => const _HomeLoading(),
                error: (error, _) => _HomeError(message: error.toString()),
                data: (data) => _HomeBody(state: data),
              ),
              // Renders nothing: the one-time battery-optimisation ask. Mounted
              // only once home data exists, which is also the point where the
              // notification service has finished initialising and the system
              // access state behind the question is a real read.
              if (state != null) const AlarmAccessGate(),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.tera),
                _DevAdhanPreview(
                  title:
                      state?.nextPrayer?.kind.displayName ??
                      PrayerKind.maghrib.displayName,
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
  const _HomeHeader({required this.locationMissing});

  /// Surfaces the location failure as a quiet marker beside the app title —
  /// tapping it jumps straight to Settings to pick a city.
  final bool locationMissing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          UiText(
            AppConstants.appName,
            type: UiTextType.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          if (locationMissing) ...[
            const SizedBox(width: AppSpacing.md),
            Tooltip(
              message: 'Location unavailable — tap to set one in Settings',
              child: InkResponse(
                key: const Key('location-missing-indicator'),
                onTap: () => Navigator.of(context).pushNamed('/settings'),
                radius: AppSpacing.touch,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: AppIconSize.md,
                    color: scheme.error,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
            color: scheme.onSurfaceVariant,
            tooltip: 'Settings',
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
    final day = state.day;
    final mutedIds = ref.watch(mutedPrayersProvider).value ?? const <String>{};

    if (day == null) {
      return _HomeError(message: state.error ?? 'Unable to load prayer times.');
    }

    final now = state.now;
    final next = state.nextPrayer;
    final sunset = day.sunset;
    final sunsetIn = sunset.difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        UiText(
          TimeFormatter.gregorian(now),
          type: UiTextType.bodyMedium,
          textAlign: TextAlign.center,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiText(
              TimeFormatter.hijri(now).toUpperCase(),
              type: UiTextType.labelSmall,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              letterSpacing: 1.2,
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: UiText(
                state.locationName,
                type: UiTextType.labelSmall,
                overflow: TextOverflow.ellipsis,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.block),
        CountdownHero(
          nextPrayer: next,
          currentPrayer: state.currentPrayer,
          nextIn: state.nextIn,
          progress: state.progress,
        ),
        const SizedBox(height: AppSpacing.emphasis),
        SectionHeader(
          label: 'Daily Schedule',
          trailing: UiText(
            day.methodName,
            type: UiTextType.labelSmall,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final prayer in day.prayers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: PrayerScheduleTile(
              prayer: prayer,
              status: _statusFor(prayer, now, next),
              muted: mutedIds.contains(
                NotificationService.prayerIdFor(day.date, prayer.kind),
              ),
              onToggleMute: () => ref
                  .read(mutedPrayersProvider.notifier)
                  .toggle(
                    NotificationService.prayerIdFor(day.date, prayer.kind),
                  ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        SolarCard(day: day),
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          children: [
            Expanded(
              child: UiText(
                state.methodLabel.toUpperCase(),
                type: UiTextType.labelSmall,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            Icon(
              Icons.wb_twilight,
              size: AppIconSize.sm,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            UiText(
              (sunsetIn.isNegative
                      ? 'Sunset ${TimeFormatter.clock(sunset)}'
                      : 'Sunset in ${TimeFormatter.longCountdown(sunsetIn)}')
                  .toUpperCase(),
              type: UiTextType.labelSmall,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.huge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: AppIconSize.xs,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.sm),
            UiText(
              'Private & offline. No data leaves your device.',
              type: UiTextType.labelSmall,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ],
    );
  }

  PrayerTileStatus _statusFor(
    PrayerTime prayer,
    DateTime now,
    PrayerTime? next,
  ) {
    if (prayer.time.isAfter(now)) {
      if (next != null &&
          next.kind == prayer.kind &&
          next.time == prayer.time) {
        return PrayerTileStatus.active;
      }
      return PrayerTileStatus.upcoming;
    }
    return PrayerTileStatus.passed;
  }
}

/// Debug-only harness for the full-screen adhan presenter.
///
/// Raises the presenter through the real
/// [NotificationService.showAdhanOverlay] entry point (same route transition,
/// same Stop/volume-key teardown as a live adhan) so the alarm UI can be
/// iterated on without waiting for a prayer time or granting permissions.
/// The whole widget is behind `kDebugMode`, so release builds never see it.
class _DevAdhanPreview extends ConsumerWidget {
  const _DevAdhanPreview({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      ambient: false,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
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
              UiText(
                'DEV ONLY',
                type: UiTextType.labelSmall,
                color: scheme.tertiary,
                letterSpacing: 1.4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Preview "$title" adhan',
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
            'Pushes the real full-screen presenter. Stop and the volume keys '
            'behave exactly like a live alarm.',
            type: UiTextType.labelSmall,
            textAlign: TextAlign.center,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.offsetXl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.offsetLg),
      child: AppCard(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderColor: scheme.error.withValues(alpha: 0.25),
        ambient: false,
        child: Column(
          children: [
            UiText(
              'Could not determine prayer times',
              type: UiTextType.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            UiText(
              message,
              type: UiTextType.bodyMedium,
              textAlign: TextAlign.center,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PulseDot(color: scheme.primary, size: AppSpacing.sm),
            const SizedBox(height: AppSpacing.md),
            UiText(
              'Pull down to retry, or set a city or GPS in Settings.',
              type: UiTextType.labelSmall,
              textAlign: TextAlign.center,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
