import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';

/// Leading icon badge — the tonal circle (or rounded square) that anchors
/// settings rows, section headers and card titles.
///
/// Defaults to the secondary tonal surface used by list tiles so every leading
/// icon in a group stays visually aligned.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = AppSpacing.control,
    this.iconSize = AppIconSize.lg,
    this.color,
    this.foregroundColor,
    this.square = false,
    this.borderRadius = AppRadius.md,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  /// Badge fill. Defaults to `secondaryContainer` tinted to 55%.
  final Color? color;

  /// Icon colour. Defaults to `onSecondaryContainer`.
  final Color? foregroundColor;

  /// Circle by default; set to `true` for rounded squares (card titles).
  final bool square;

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = color ?? scheme.secondaryContainer.withValues(alpha: 0.55);
    final iconColor = foregroundColor ?? scheme.onSecondaryContainer;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(borderRadius) : null,
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}