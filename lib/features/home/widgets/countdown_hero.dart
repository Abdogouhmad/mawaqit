import 'package:flutter/material.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The Home screen's one focal surface: the next prayer and its countdown.
///
/// Everything here is quiet except the number. The card uses the app's standard
/// tonal container; the only accent is the primary-coloured countdown figures
/// and the slim temporal progress track. Only the progress value animates, and
/// that animation is suppressed by both reduce-motion signals.
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
    final next = nextPrayer;
    if (next == null) {
      return const SizedBox(height: AppSpacing.offsetXl);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final nextName = next.kind.localized(l10n);
    final countdown = TimeFormatter.countdown(nextIn);
    // Above roughly 130% text the one-line rich title starts shrinking to stay
    // inside 360dp. Stacking first keeps each figure at its semantic size and
    // only scales a single line if a locale is genuinely too wide.
    final largeText =
        MediaQuery.textScalerOf(context).scale(AppFontSize.md) >
        AppFontSize.md * AppLayout.largeTextScaleThreshold;
    final subtitle = currentPrayer == null
        ? l10n.homeDayBeginsWith(nextName)
        : l10n.homePrayerEnded(
            currentPrayer!.kind.localized(l10n),
            TimeFormatter.clock(currentPrayer!.time),
          );

    return Semantics(
      label: '${l10n.homeNextPrayer}, $nextName, $countdown',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.tera),
        child: Column(
          children: [
            AppPill(
              label: l10n.homeNextPrayer,
              leading: PulseDot(color: scheme.primary, glow: false),
              color: scheme.primary,
              dense: true,
              letterSpacing: AppTypeDetail.overlineTracking,
            ),
            const SizedBox(height: AppSpacing.block),
            _CountdownText(
              prayerName: nextName,
              countdown: countdown,
              textTheme: theme.textTheme,
              scheme: scheme,
              largeText: largeText,
            ),
            const SizedBox(height: AppSpacing.md),
            _PrayerMeta(
              prayerTime: TimeFormatter.clock(next.time),
              subtitle: subtitle,
              scheme: scheme,
              largeText: largeText,
            ),
            const SizedBox(height: AppSpacing.tera),
            _PrayerProgress(
              progress: progress,
              startTime: currentPrayer?.time,
              endTime: next.time,
              scheme: scheme,
            ),
          ],
        ),
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
    required this.largeText,
  });

  final String prayerName;
  final String countdown;
  final TextTheme textTheme;
  final ColorScheme scheme;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final base = largeText
        ? textTheme.headlineMedium!
        : textTheme.displayMedium!;

    final nameStyle = AppTheme.numerals(
      base.copyWith(color: scheme.onSurface, fontWeight: AppWeight.semibold),
    );
    final countdownStyle = AppTheme.numerals(
      base.copyWith(
        color: scheme.primary,
        fontWeight: AppWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (largeText) {
      return Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayerName,
              textAlign: TextAlign.center,
              style: nameStyle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              countdown,
              textAlign: TextAlign.center,
              style: countdownStyle,
            ),
          ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$prayerName ',
              style: nameStyle.copyWith(
                letterSpacing: AppTypeDetail.heroTracking,
              ),
            ),
            TextSpan(
              text: 'in ',
              style: AppTheme.numerals(
                base.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: AppWeight.regular,
                  letterSpacing: AppTypeDetail.heroTracking,
                ),
              ),
            ),
            TextSpan(
              text: countdown,
              style: countdownStyle.copyWith(
                letterSpacing: AppTypeDetail.heroTracking,
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
    required this.largeText,
  });

  final String prayerTime;
  final String subtitle;
  final ColorScheme scheme;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final time = UiText(
      prayerTime,
      type: UiTextType.titleMedium,
      fontSize: AppFontSize.lg,
      textAlign: largeText ? TextAlign.center : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      color: scheme.onSurface,
      fontWeight: AppWeight.semibold,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
    final detail = AppPill(
      label: subtitle,
      dense: true,
      backgroundColor: scheme.surfaceContainer,
    );

    if (largeText) {
      return Column(
        children: [
          time,
          const SizedBox(height: AppSpacing.sm),
          detail,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        time,
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: detail),
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
  });

  final double progress;
  final DateTime? startTime;
  final DateTime endTime;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final duration = AppSpring.durationOf(context, fallback: AppMotion.effects);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.progress),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              duration: duration,
              curve: AppMotion.standard,
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: AppSize.progressTrackHeight,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: UiText(
                  startTime == null
                      ? AppLocalizations.of(context).homeStart
                      : TimeFormatter.clock(startTime!),
                  type: UiTextType.labelSmall,
                  color: scheme.onSurfaceVariant,
                  fontWeight: AppWeight.medium,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: UiText(
                  TimeFormatter.clock(endTime),
                  textAlign: TextAlign.end,
                  type: UiTextType.labelSmall,
                  color: scheme.primary,
                  fontWeight: AppWeight.bold,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
