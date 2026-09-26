import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/app_theme.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Lightweight M3 Expressive countdown hero.
///
/// Design principles:
/// - Countdown remains the primary visual focus.
/// - Uses ColorScheme surfaces instead of gradients/shadows.
/// - Expressive asymmetric shapes without expensive decoration.
/// - Progress remains useful but visually quiet.
/// - Only the progress value animates when it changes.
class CountdownHero extends StatelessWidget {
  const CountdownHero({
    super.key,
    required this.nextPrayer,
    required this.currentPrayer,
    required this.nextIn,
    required this.progress,
  });

  final PrayerTime? nextPrayer;
  final PrayerTime? currentPrayer;
  final Duration nextIn;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final next = nextPrayer;

    if (next == null) {
      return const SizedBox(height: AppSpacing.offsetXl);
    }

    final isLight = theme.brightness == Brightness.light;

    final countdown = TimeFormatter.countdown(nextIn);

    final subtitle = currentPrayer == null
        ? 'The day begins with ${next.kind.displayName}'
        : '${currentPrayer!.kind.displayName} ended '
              '${TimeFormatter.clock(currentPrayer!.time)}';

    final startTime = currentPrayer?.time;
    final endTime = next.time;

    return Column(
      children: [
        /// Expressive status badge.
        _NextPrayerBadge(scheme: scheme),

        const SizedBox(height: AppSpacing.lg),

        /// Main countdown.
        _CountdownText(
          prayerName: next.kind.displayName,
          countdown: countdown,
          textTheme: textTheme,
          scheme: scheme,
        ),

        const SizedBox(height: AppSpacing.sm),

        /// Prayer time + context.
        _PrayerMeta(
          prayerTime: TimeFormatter.clock(next.time),
          subtitle: subtitle,
          scheme: scheme,
        ),

        const SizedBox(height: AppSpacing.xl),

        /// Lightweight temporal progress surface.
        _PrayerProgress(
          progress: progress,
          startTime: startTime,
          endTime: endTime,
          scheme: scheme,
          isLight: isLight,
        ),
      ],
    );
  }
}

class _NextPrayerBadge extends StatelessWidget {
  const _NextPrayerBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(color: scheme.primary, size: 7, glow: false),
          const SizedBox(width: 8),
          UiText(
            'NEXT PRAYER',
            type: UiTextType.labelMedium,
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ],
      ),
    );
  }
}

class _CountdownText extends StatelessWidget {
  const _CountdownText({
    required this.prayerName,
    required this.countdown,
    required this.textTheme,
    required this.scheme,
  });

  final String prayerName;
  final String countdown;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$prayerName ',
              style: AppTheme.numerals(
                textTheme.displayMedium!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
            ),
            TextSpan(
              text: 'in ',
              style: AppTheme.numerals(
                textTheme.displayMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -1.4,
                ),
              ),
            ),
            TextSpan(
              text: countdown,
              style: AppTheme.numerals(
                textTheme.displayMedium!.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerMeta extends StatelessWidget {
  const _PrayerMeta({
    required this.prayerTime,
    required this.subtitle,
    required this.scheme,
  });

  final String prayerTime;
  final String subtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UiText(
          prayerTime,
          type: UiTextType.titleMedium,
          fontSize: AppFontSize.lg,
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),

        const SizedBox(width: AppSpacing.sm),

        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: UiText(
              subtitle,
              type: UiTextType.labelMedium,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerProgress extends StatelessWidget {
  const _PrayerProgress({
    required this.progress,
    required this.startTime,
    required this.endTime,
    required this.scheme,
    required this.isLight,
  });

  final double progress;
  final DateTime? startTime;
  final DateTime endTime;
  final ColorScheme scheme;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.progress),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: isLight ? .45 : .25),
          ),
        ),
        child: Column(
          children: [
            /// Progress track.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  );
                },
              ),
            ),

            const SizedBox(height: 9),

            /// Timeline labels.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiText(
                  startTime == null ? 'Start' : TimeFormatter.clock(startTime!),
                  type: UiTextType.labelSmall,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                UiText(
                  TimeFormatter.clock(endTime),
                  type: UiTextType.labelSmall,
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
