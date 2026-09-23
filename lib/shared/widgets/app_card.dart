import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';

/// Soft rounded card with hairline border, tonal fill and a whisper-soft
/// emerald ambient shadow (design "Level 1 / Level 2" containers).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xxxl),
    this.color,
    this.borderColor,
    this.radius = AppRadius.xl,
    this.ambient = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool ambient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final scheme = Theme.of(context).colorScheme;
    final effectiveShadow = ambient
        ? [
            BoxShadow(
              color: (isLight
                      ? const Color(0xFF2E7D5B)
                      : const Color(0xFF3E9B76))
                  .withValues(alpha: isLight ? 0.05 : 0.12),
              blurRadius: AppSpacing.giga,
              offset: const Offset(0, AppSpacing.md),
            ),
          ]
        : null;

    final decoration = BoxDecoration(
      color: color ?? scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (isLight
                ? const Color(0x0A000000)
                : const Color(0x0FFFFFFF)),
      ),
      boxShadow: effectiveShadow,
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}