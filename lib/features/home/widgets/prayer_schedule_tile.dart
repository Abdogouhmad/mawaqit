import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/pulse_dot.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/l10n/enum_localization.dart';

enum PrayerTileStatus { passed, active, upcoming }

/// Minimum size for anything tappable, per the platform accessibility
/// guidelines. The mute glyph is 17px, so on its own it produced a 25px hit
/// area — small enough that muting the wrong prayer was an easy accident, and
/// unreachable for anyone using a screen reader's touch exploration.
const double kMinTouchTarget = 48;

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
      // Reduced from 16 to 8: the mute control now occupies a full 48dp touch
      // target, and without giving some of that height back every tile would
      // have grown by 23px in a list of five.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.jumbo,
        vertical: AppSpacing.md,
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
          // Name, countdown and time are announced as one node: read
          // separately they were three unrelated fragments ("Fajr", "Isha in
          // 1h 20m", "5:42 PM") with the relationship left to the listener to
          // infer. Kept as its own child of the row so the mute control beside
          // it survives as a separate button instead of being merged into it.
          Expanded(
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: UiText(
                      prayer.kind.localized(AppLocalizations.of(context)),
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
                ],
              ),
            ),
          ),
          // Narrowed from 10 to 2 to absorb the wider touch target.
          const SizedBox(width: AppSpacing.xxs),
          _muteControl(context, scheme),
        ],
      ),
    );
  }

  /// Adhan mute toggle. One widget for both visual states so the muted pill
  /// cannot drift out of step with the icon's target size, and so both expose
  /// the same `toggled` state to a screen reader — which previously read
  /// "Muted" at best, and nothing at all for the icon state.
  Widget _muteControl(BuildContext context, ColorScheme scheme) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final passed = status == PrayerTileStatus.passed;
    final active = status == PrayerTileStatus.active;
    final enabled = onToggleMute != null;

    return Semantics(
      button: true,
      toggled: muted,
      enabled: enabled,
      label: AppLocalizations.of(
        context,
      ).prayerAdhanLabel(prayer.kind.localized(AppLocalizations.of(context))),
      hint: muted
          ? AppLocalizations.of(context).prayerUnmuteHint
          : AppLocalizations.of(context).prayerMuteHint,
      excludeSemantics: true,
      child: Tooltip(
        message: muted
            ? AppLocalizations.of(context).prayerTapToUnmute
            : AppLocalizations.of(context).prayerTapToMute,
        child: _TouchTarget(
          child: muted
              ? AppPill(
                  key: const Key('mute-toggle'),
                  label: AppLocalizations.of(context).prayerMuted,
                  icon: Icons.volume_off,
                  dense: true,
                  onTap: enabled ? _handleToggle : null,
                  backgroundColor: scheme.tertiaryContainer.withValues(
                    alpha: isLight ? 0.6 : 0.35,
                  ),
                  foregroundColor: scheme.onTertiaryContainer,
                )
              : InkResponse(
                  key: const Key('notification-mute-toggle'),
                  onTap: enabled ? _handleToggle : null,
                  radius: kMinTouchTarget / 2,
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
    );
  }
}

/// Grows an interactive control to [kMinTouchTarget] without changing how it
/// looks, so accessibility does not cost the design its density.
class _TouchTarget extends StatelessWidget {
  const _TouchTarget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
      child: Center(child: child),
    );
  }
}
