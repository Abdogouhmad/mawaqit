import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Pill-shaped status/chip: the small icon + label capsule used for "Muted",
/// "Update available", "In X min", status labels and toast-like accents.
///
/// The default neutral tone reads `surfaceContainerHighest` with a muted
/// label. Pass an accent [color] to get a tonal pill (tinted fill + accent
/// icon/label), and override [backgroundColor] / [foregroundColor] directly
/// for fully custom cases (e.g. the calendar's "NEXT PRAYER" marker).
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.color,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.onTap,
    this.dense = false,
    this.expanded = false,
    this.letterSpacing = 0.4,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Color? color;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool dense;
  final bool expanded;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color;
    final background =
        backgroundColor ??
        (accent != null
            ? accent.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6));
    final foreground = foregroundColor ?? accent ?? scheme.onSurfaceVariant;

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ] else if (icon != null) ...[
          Icon(icon, size: AppIconSize.sm, color: foreground),
          const SizedBox(width: AppSpacing.xs + 2),
        ],
        UiText(
          label,
          type: UiTextType.labelSmall,
          color: foreground,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          style: const TextStyle(height: 1),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? AppSpacing.lg : AppSpacing.giga,
            vertical: dense ? AppSpacing.xs : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
