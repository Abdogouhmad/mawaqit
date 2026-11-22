import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

enum PrayerTileStatus { passed, active, upcoming }

/// One row in the daily prayer timeline.
///
/// The rows share one card and a thin rail on the leading side, so the five
/// prayers read as a sequence rather than five unrelated cards. The active row
/// is the only one that takes a filled container — a selected state, not
/// decoration — and its mute control stays a separate semantics node so screen
/// readers still announce it as a toggle.
class PrayerScheduleTile extends StatelessWidget {
  const PrayerScheduleTile({
    super.key,
    required this.prayer,
    required this.status,
    this.countdownLabel,
    this.muted = false,
    this.onToggleMute,
    this.isLast = false,
  });

  final PrayerTime prayer;
  final PrayerTileStatus status;
  final String? countdownLabel;
  final bool muted;
  final VoidCallback? onToggleMute;

  /// Hides the connecting rail on the final prayer of the day.
  final bool isLast;

  void _handleToggle() {
    HapticFeedback.selectionClick();
    onToggleMute?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final active = status == PrayerTileStatus.active;
    final passed = status == PrayerTileStatus.passed;

    final foreground = active
        ? scheme.onPrimaryContainer
        : passed
        ? scheme.onSurfaceVariant.withValues(alpha: AppOpacity.secondaryText)
        : scheme.onSurface;

    return AnimatedContainer(
      duration: AppSpring.durationOf(context, fallback: AppMotion.control),
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: active
              ? AppColors.transparent
              : scheme.outlineVariant.withValues(alpha: AppOpacity.hairline),
        ),
      ),
      child: Row(
        children: [
          _TimelineMarker(
            scheme: scheme,
            active: active,
            passed: passed,
            isLast: isLast,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: UiText(
                      prayer.kind.localized(l10n),
                      type: UiTextType.titleMedium,
                      color: foreground,
                      fontWeight: active ? AppWeight.bold : AppWeight.medium,
                    ),
                  ),
                  if (active && countdownLabel != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: AppPill(
                        label: countdownLabel!,
                        icon: Icons.timer_outlined,
                        dense: true,
                        backgroundColor: scheme.surfaceContainerHighest,
                        foregroundColor: foreground,
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: UiText(
                      TimeFormatter.clock(prayer.time),
                      type: UiTextType.titleMedium,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      color: foreground,
                      fontWeight: active ? AppWeight.bold : AppWeight.medium,
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _muteControl(l10n, scheme, active, passed),
        ],
      ),
    );
  }

  Widget _muteControl(
    AppLocalizations l10n,
    ColorScheme scheme,
    bool active,
    bool passed,
  ) {
    final enabled = onToggleMute != null;
    final label = l10n.prayerAdhanLabel(prayer.kind.localized(l10n));

    return Semantics(
      button: true,
      toggled: muted,
      enabled: enabled,
      label: label,
      hint: muted ? l10n.prayerUnmuteHint : l10n.prayerMuteHint,
      excludeSemantics: true,
      child: AppIconButton(
        icon: muted ? Icons.volume_off : Icons.volume_up,
        tooltip: muted ? l10n.prayerTapToUnmute : l10n.prayerTapToMute,
        onPressed: enabled ? _handleToggle : null,
        variant: muted
            ? AppIconButtonVariant.tonal
            : AppIconButtonVariant.standard,
        color: active
            ? scheme.onPrimaryContainer
            : passed
            ? scheme.onSurfaceVariant.withValues(
                alpha: AppOpacity.secondaryText,
              )
            : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.scheme,
    required this.active,
    required this.passed,
    required this.isLast,
  });

  final ColorScheme scheme;
  final bool active;
  final bool passed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.touch,
      height: AppSpacing.touch,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          if (!isLast)
            Container(
              width: AppStroke.hairline,
              height: AppSpacing.touch,
              color: scheme.outlineVariant.withValues(
                alpha: AppOpacity.hairline,
              ),
            ),
          if (active)
            PulseDot(color: scheme.onPrimaryContainer, glow: false)
          else
            Container(
              width: AppSize.pulseDot,
              height: AppSize.pulseDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed
                    ? scheme.outlineVariant.withValues(
                        alpha: AppOpacity.faintMark,
                      )
                    : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
