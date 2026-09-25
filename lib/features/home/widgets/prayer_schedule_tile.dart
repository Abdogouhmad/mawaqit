import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

enum PrayerTileStatus { passed, active, upcoming }

/// A single row in the daily prayer schedule.
class PrayerScheduleTile extends StatelessWidget {
  const PrayerScheduleTile({
    super.key,
    required this.prayer,
    required this.status,
    this.countdownLabel,
    this.muted = false,
    this.onToggleMute,
  });

  final PrayerTime prayer;
  final PrayerTileStatus status;
  final String? countdownLabel;
  final bool muted;
  final VoidCallback? onToggleMute;

  void _handleToggle() {
    HapticFeedback.selectionClick();
    onToggleMute?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final active = status == PrayerTileStatus.active;
    final passed = status == PrayerTileStatus.passed;

    final nameColor = active
        ? scheme.onSurface
        : passed
        ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
        : scheme.onSurface;
    final timeColor = active
        ? scheme.onSurface
        : passed
        ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;

    final Color background;
    final Color border;
    final List<BoxShadow>? shadow;

    if (active) {
      background = isLight
          ? scheme.primary.withValues(alpha: 0.06)
          : scheme.primary.withValues(alpha: 0.10);
      border = scheme.primary.withValues(alpha: 0.45);
      shadow = [
        BoxShadow(
          color: scheme.primary.withValues(alpha: isLight ? 0.10 : 0.20),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (passed) {
      background = isLight ? AppColors.tileInactiveLight : AppColors.cardDark;
      border = isLight
          ? AppColors.hairlineOverlayLight
          : AppColors.hairlineOverlayDark;
      shadow = null;
    } else {
      background = scheme.surfaceContainerLowest;
      border = isLight
          ? AppColors.hairlineOverlayLight
          : AppColors.hairlineOverlayDark;
      shadow = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.jumbo,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          active ? AppRadius.xl : AppRadius.lg,
        ),
        border: Border.all(color: border),
        boxShadow: shadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.xl,
            child: active
                ? PulseDot(color: scheme.primary, size: 8)
                : Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: passed
                          ? scheme.outlineVariant
                          : scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: UiText(
              prayer.kind.displayName,
              type: UiTextType.titleMedium,
              color: nameColor,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (active && countdownLabel != null) ...[
            AppPill(
              label: countdownLabel!,
              icon: Icons.notifications_active,
              dense: true,
              backgroundColor: scheme.surfaceContainerLowest,
              foregroundColor: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          UiText(
            TimeFormatter.clock(prayer.time),
            type: UiTextType.titleMedium,
            color: timeColor,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (muted)
            Tooltip(
              message: 'Tap to unmute adhan',
              child: AppPill(
                key: const Key('mute-toggle'),
                label: 'Muted',
                icon: Icons.volume_off,
                dense: true,
                onTap: onToggleMute == null ? null : _handleToggle,
                backgroundColor: scheme.tertiaryContainer.withValues(
                  alpha: isLight ? 0.6 : 0.35,
                ),
                foregroundColor: scheme.onTertiaryContainer,
              ),
            )
          else
            Tooltip(
              message: 'Tap to mute adhan',
              child: InkResponse(
                key: const Key('notification-mute-toggle'),
                onTap: onToggleMute == null ? null : _handleToggle,
                radius: AppSpacing.lg,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    passed
                        ? Icons.notifications_off_outlined
                        : active
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: AppIconSize.md,
                    color: active
                        ? scheme.primary
                        : passed
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
