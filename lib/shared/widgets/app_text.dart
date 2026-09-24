import 'package:flutter/material.dart';

/// Shared expressive typography helpers so captions, eyebrows and supporting
/// copy stay consistent (and themeable in one place) across the whole app.
abstract final class AppText {
  /// Uppercase, letterspaced micro-label — section eyebrows, "ADHAN", badges.
  static Widget eyebrow(
    BuildContext context,
    String text, {
    Color? color,
    double tracking = 1.4,
    TextStyle? style,
    TextAlign? textAlign,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: (style ?? Theme.of(context).textTheme.labelSmall)?.copyWith(
        color: color ?? scheme.onSurfaceVariant,
        letterSpacing: tracking,
      ),
    );
  }

  /// Supporting/secondary copy coloured `onSurfaceVariant`.
  static Widget support(
    BuildContext context,
    String text, {
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      textAlign: textAlign,
      style: (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
        color: color ?? scheme.onSurfaceVariant,
        fontStyle: fontStyle,
      ),
    );
  }
}