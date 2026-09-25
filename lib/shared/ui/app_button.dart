import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';

/// One shared action-button API for the four M3 button variants, with a
/// built-in loading state and optional full width.
///
/// Wraps the platform `FilledButton` / `OutlinedButton` / `TextButton` widgets
/// so the whole app talks to a single component: any size, radius or colour
/// change for an expressive makeover is applied here once.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.expanded = true,
    this.loading = false,
    this.loadingLabel,
    this.minHeight = AppSpacing.touch,
    this.radius = AppRadius.md,
    this.backgroundColor,
    this.foregroundColor,
    this.labelStyle,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expanded;
  final bool loading;
  final String? loadingLabel;
  final double minHeight;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, minHeight)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.giga,
          vertical: AppSpacing.xxl,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      backgroundColor: backgroundColor != null
          ? WidgetStatePropertyAll(backgroundColor)
          : null,
      foregroundColor: foregroundColor != null
          ? WidgetStatePropertyAll(foregroundColor)
          : null,
      textStyle: WidgetStatePropertyAll(
        labelStyle ??
            textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );

    final effectiveOnPressed = loading ? null : onPressed;

    final Widget button = switch (variant) {
      AppButtonVariant.filled => FilledButton.icon(
        style: style,
        onPressed: effectiveOnPressed,
        icon: _trait(context),
        label: Text(_label),
      ),
      AppButtonVariant.tonal => FilledButton.tonalIcon(
        style: style,
        onPressed: effectiveOnPressed,
        icon: _trait(context),
        label: Text(_label),
      ),
      AppButtonVariant.outlined => OutlinedButton.icon(
        style: style,
        onPressed: effectiveOnPressed,
        icon: _trait(context),
        label: Text(_label),
      ),
      AppButtonVariant.text => TextButton.icon(
        style: style,
        onPressed: effectiveOnPressed,
        icon: _trait(context),
        label: Text(_label),
      ),
    };

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  String get _label => loading ? loadingLabel ?? label : label;

  Widget _trait(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: foregroundColor ?? scheme.onPrimary,
        ),
      );
    }
    if (icon == null) return const SizedBox.shrink();
    return Icon(
      icon,
      size:
          variant == AppButtonVariant.filled ||
              variant == AppButtonVariant.tonal
          ? AppIconSize.xl
          : AppIconSize.lg,
    );
  }
}

enum AppButtonVariant { filled, tonal, outlined, text }
