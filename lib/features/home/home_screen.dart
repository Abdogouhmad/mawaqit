import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/widgets/app_card.dart';
import 'package:mawaqit/shared/widgets/pulse_dot.dart';
import 'package:mawaqit/shared/widgets/section_header.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/home/widgets/countdown_hero.dart';
import 'package:mawaqit/features/home/widgets/prayer_schedule_tile.dart';
import 'package:mawaqit/features/home/widgets/solar_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeControllerProvider);

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
              const _HomeHeader(),
              asyncState.when(
                loading: () => const _HomeLoading(),
                error: (error, _) => _HomeError(message: error.toString()),
                data: (state) => _HomeBody(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          Text(
            AppConstants.appName,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
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
    final textTheme = Theme.of(context).textTheme;
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
        Text(
          TimeFormatter.gregorian(now),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TimeFormatter.hijri(now).toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                letterSpacing: 1.2,
              ),
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
              child: Text(
                state.locationName,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  letterSpacing: 1.2,
                ),
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
          trailing: Text(
            day.methodName,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final prayer in day.prayers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: PrayerScheduleTile(
              prayer: prayer,
              status: _statusFor(prayer, now, next),
              countdownLabel: _countdownFor(prayer, next, state),
              muted: mutedIds
                  .contains(NotificationService.prayerIdFor(day.date, prayer.kind)),
              onToggleMute: () => ref
                  .read(mutedPrayersProvider.notifier)
                  .toggle(NotificationService.prayerIdFor(day.date, prayer.kind)),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        SolarCard(day: day),
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          children: [
            Expanded(
              child: Text(
                'CALCULATION: ${state.methodLabel.toUpperCase()}',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Icon(
              Icons.wb_twilight,
              size: AppIconSize.sm,
              color: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              sunsetIn.isNegative
                  ? 'SUNSET ${TimeFormatter.clock(sunset).toUpperCase()}'
                  : 'SUNSET IN ${TimeFormatter.longCountdown(sunsetIn).toUpperCase()}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                letterSpacing: 0.8,
              ),
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
            Text(
              'Private & offline. No data leaves your device.',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
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

  String? _countdownFor(
    PrayerTime prayer,
    PrayerTime? next,
    HomeState state,
  ) {
    if (next == null) return null;
    if (next.kind == prayer.kind && next.time == prayer.time) {
      return 'In ${TimeFormatter.countdown(state.nextIn)}';
    }
    return null;
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.offsetLg),
      child: AppCard(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderColor: scheme.error.withValues(alpha: 0.25),
        ambient: false,
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, color: scheme.error),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Could not determine prayer times',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PulseDot(color: scheme.primary, size: AppSpacing.sm),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pull down to retry, or set a city or GPS in Settings.',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}