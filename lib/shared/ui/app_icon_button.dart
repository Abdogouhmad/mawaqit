import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';

/// How an icon button sits on its surface.
enum AppIconButtonVariant { standard, tonal, filled }

/// One shared icon-action API so every toolbar, card header and sheet uses the
/// same hit target, shape and interaction colour.
///
/// The default is the quiet standard variant. Tonal and filled are opt-in for
/// the one or two actions on a screen that genuinely deserve more weight.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.selected = false,
    this.iconSize = AppIconSize.xl,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final bool selected;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color fill, Color foreground) = switch ((variant, selected)) {
      (_, true) => (scheme.primaryContainer, scheme.onPrimaryContainer),
      (AppIconButtonVariant.filled, false) => (
        scheme.primary,
        scheme.onPrimary,
      ),
      (AppIconButtonVariant.tonal, false) => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      (AppIconButtonVariant.standard, false) => (
        AppColors.transparent,
        scheme.onSurfaceVariant,
      ),
    };

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      color: color ?? foreground,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touch,
        minHeight: AppSpacing.touch,
      ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? fill,
        foregroundColor: color ?? foreground,
        disabledBackgroundColor: backgroundColor ?? fill,
        disabledForegroundColor: scheme.onSurface.withValues(
          alpha: AppOpacity.hairline,
        ),
        shape: const CircleBorder(),
        minimumSize: const Size.square(AppSpacing.touch),
      ),
    );
  }
}
