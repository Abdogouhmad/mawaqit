import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/widgets/pulse_dot.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
      background = isLight ? const Color(0xFFF4F4F1) : const Color(0xFF181918);
      border = isLight ? const Color(0x0A000000) : const Color(0x0FFFFFFF);
      shadow = null;
    } else {
      background = scheme.surfaceContainerLowest;
      border = isLight ? const Color(0x0A000000) : const Color(0x0FFFFFFF);
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
            child: Text(
              prayer.kind.displayName,
              style: textTheme.titleMedium?.copyWith(
                color: nameColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (active && countdownLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: AppIconSize.sm,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    countdownLabel!,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          Text(
            TimeFormatter.clock(prayer.time),
            style: textTheme.titleMedium?.copyWith(
              color: timeColor,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (muted)
            Tooltip(
              message: 'Tap to unmute adhan',
              child: InkWell(
                key: const Key('mute-toggle'),
                onTap: onToggleMute == null ? null : _handleToggle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(
                      alpha: isLight ? 0.6 : 0.35,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_off,
                        size: AppIconSize.sm,
                        color: scheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Muted',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
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
