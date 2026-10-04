import 'package:flutter/material.dart';

import 'package:mawaqit/core/const/app_constants.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';

/// The app's type scale.
///
/// Extracted from [AppTheme] so the scale is one reviewable block rather than
/// interleaved with a dozen `ButtonThemeData`s. Two rules the rest of the app
/// depends on:
///
///  * every size comes from [AppFontSize]; there are no font-size literals in
///    widgets;
///  * anything showing a *time* must go through [tabular], or the glyphs re-flow
///    every second as the digits change width.
abstract final class AppTextTheme {
  const AppTextTheme._();

  static TextTheme build({
    required ColorScheme scheme,
    required Brightness brightness,
    required bool arabic,
  }) {
    final base = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: AppConstants.fontFamily,
      fontFamilyFallback: AppConstants.fontFamilyFallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final scale = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: AppFontSize.displayLg,
        height: 1.1,
        fontWeight: FontWeight.w200,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: AppFontSize.displayMd,
        height: 1.15,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppFontSize.displaySm,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: AppFontSize.headline,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppFontSize.xxl,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppFontSize.xl,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppFontSize.lg,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppFontSize.md,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppFontSize.md,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: AppFontSize.sm,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppFontSize.xs,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );

    return arabic ? untacked(scale) : scale;
  }

  /// The height a single line of [style] actually occupies under [scaler].
  ///
  /// `fontSize * height` is *not* that number, and assuming it is overflows any
  /// layout that sizes itself from the theme. Flutter resolves the line box from
  /// the font's own ascent/descent (`TextHeightBehavior` multiplies the metrics'
  /// height by the requested height), so the true figure runs a few percent
  /// taller than the arithmetic suggests — enough to clip a pinned header at
  /// 200% text, where the margin is what is being spent.
  ///
  /// Measured rather than derived because the font is bundled and its metrics are
  /// not knowable from the style alone.
  static double lineHeight(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: 'Á', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Tabular figures for countdowns and prayer times.
  ///
  /// Without this the countdown visibly jitters: a proportional `1` is narrower
  /// than a `0`, so every tick the run of digits changes width and the whole
  /// string shifts sideways. The weight variation matches the light numerals
  /// used elsewhere in the hero.
  static TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontVariations: const [FontVariation('wght', 300)],
  );

  /// Strips every `letterSpacing` from [theme].
  ///
  /// The tracking above is dialled in for Latin: negative on the large display
  /// sizes, positive on the small uppercase-ish labels. None of it transfers to
  /// Arabic. Arabic joins its letters through contextual forms, so inserting
  /// space between glyphs breaks the word into disconnected letters — it reads
  /// as broken rather than as "spaced out", which is why Arabic typesetting
  /// guidance is to leave tracking at zero.
  ///
  /// Done as a post-pass over the finished scale rather than by branching at each
  /// of the eleven `letterSpacing` sites, so a new style cannot forget the case.
  static TextTheme untacked(TextTheme theme) => theme.copyWith(
    displayLarge: theme.displayLarge?.copyWith(letterSpacing: 0),
    displayMedium: theme.displayMedium?.copyWith(letterSpacing: 0),
    displaySmall: theme.displaySmall?.copyWith(letterSpacing: 0),
    headlineLarge: theme.headlineLarge?.copyWith(letterSpacing: 0),
    headlineMedium: theme.headlineMedium?.copyWith(letterSpacing: 0),
    headlineSmall: theme.headlineSmall?.copyWith(letterSpacing: 0),
    titleLarge: theme.titleLarge?.copyWith(letterSpacing: 0),
    titleMedium: theme.titleMedium?.copyWith(letterSpacing: 0),
    titleSmall: theme.titleSmall?.copyWith(letterSpacing: 0),
    bodyLarge: theme.bodyLarge?.copyWith(letterSpacing: 0),
    bodyMedium: theme.bodyMedium?.copyWith(letterSpacing: 0),
    bodySmall: theme.bodySmall?.copyWith(letterSpacing: 0),
    labelLarge: theme.labelLarge?.copyWith(letterSpacing: 0),
    labelMedium: theme.labelMedium?.copyWith(letterSpacing: 0),
    labelSmall: theme.labelSmall?.copyWith(letterSpacing: 0),
  );
}
