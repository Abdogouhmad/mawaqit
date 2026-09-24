import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/app_theme.dart';
import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/widgets/pulse_dot.dart';

/// Large focal countdown with temporal progress bar.
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final next = nextPrayer;

    if (next == null) {
      return const SizedBox(height: AppSpacing.offsetXl);
    }

    final countdown = TimeFormatter.countdown(nextIn);
    final subtitle = currentPrayer == null
        ? 'The day begins with ${next.kind.displayName}'
        : '${currentPrayer!.kind.displayName} ended '
              '${TimeFormatter.clock(currentPrayer!.time)}';

    final startTime = currentPrayer?.time;
    final endTime = next.time;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isLight
                ? scheme.surfaceContainer
                : AppColors.primaryDark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isLight
                ? null
                : Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.25),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseDot(color: scheme.primary, size: 7, glow: true),
              const SizedBox(width: AppSpacing.md),
              Text(
                'NEXT PRAYER',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.jumbo),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              style: AppTheme.numerals(
                textTheme.displayMedium!.copyWith(color: scheme.onSurface),
              ),
              children: [
                TextSpan(text: '${next.kind.displayName} in '),
                TextSpan(
                  text: countdown,
                  style: textTheme.displayMedium?.copyWith(
                    color: scheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TimeFormatter.clock(next.time),
              style: textTheme.titleMedium?.copyWith(
                fontSize: AppFontSize.lg,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                subtitle,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.blockLg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.progress),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: progress),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: AppSpacing.xs,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    startTime == null
                        ? 'Start'
                        : TimeFormatter.clock(startTime),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    TimeFormatter.clock(endTime),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
