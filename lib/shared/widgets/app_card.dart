import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';

/// Soft rounded card with hairline border, tonal fill and a whisper-soft
/// emerald ambient shadow (design "Level 1 / Level 2" containers).
///
/// The fill lives on the [Material] itself (matching rounded [shape] with
/// anti-aliased clipping) so the ink ripple clips to the corners — no more
/// sharp highlights poking past the radius. The ambient glow is painted by the
/// outer [DecoratedBox] so it can extend beyond the shape unclipped.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xxxl),
    this.color,
    this.borderColor,
    this.radius = AppRadius.md,
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
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: ambient
            ? [
                BoxShadow(
                  color:
                      (isLight ? AppColors.primaryLight : AppColors.primaryDark)
                          .withValues(alpha: isLight ? 0.05 : 0.12),
                  blurRadius: AppSpacing.giga,
                  offset: const Offset(0, AppSpacing.md),
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color:
                borderColor ??
                (isLight
                    ? AppColors.hairlineOverlayLight
                    : AppColors.hairlineOverlayDark),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
