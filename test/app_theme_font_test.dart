import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/app_theme.dart';

void main() {
  // The Arabic UI was silently rendering in the system font: Manrope has no
  // Arabic glyphs at all, and nothing declared a fallback. These lock in that
  // the fallback is present and that the tracking is dropped for Arabic.
  group('font wiring', () {
    test('every style falls back to Cairo for Arabic glyphs', () {
      for (final theme in [
        AppTheme.light(),
        AppTheme.light(arabic: true),
        AppTheme.dark(),
        AppTheme.dark(arabic: true),
      ]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppConstants.fontFamily);
        expect(
          theme.textTheme.bodyMedium?.fontFamilyFallback,
          contains('Cairo'),
          reason: 'Arabic would fall back to the system font without this',
        );
        // ThemeData only exposes the fallback through the styles it built, so
        // assert on a real resolved style rather than a ThemeData getter.
        expect(
          theme.textTheme.labelSmall?.fontFamilyFallback,
          contains('Cairo'),
        );
      }
    });

    test('Latin keeps its tuned letter-spacing', () {
      final t = AppTheme.light().textTheme;
      final tracked = [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
      ].whereType<TextStyle>().map((s) => s.letterSpacing);

      expect(
        tracked.any((v) => v != 0 && v != null),
        isTrue,
        reason: 'the Latin theme is expected to keep some tracking',
      );
    });

    test('Arabic drops all letter-spacing', () {
      // Tracking breaks the contextual joining of Arabic script, so every
      // style must come out at exactly 0.
      for (final theme in [
        AppTheme.light(arabic: true),
        AppTheme.dark(arabic: true),
      ]) {
        final styles = [
          theme.textTheme.displayLarge,
          theme.textTheme.displayMedium,
          theme.textTheme.displaySmall,
          theme.textTheme.headlineLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.headlineSmall,
          theme.textTheme.titleLarge,
          theme.textTheme.titleMedium,
          theme.textTheme.titleSmall,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.bodySmall,
          theme.textTheme.labelLarge,
          theme.textTheme.labelMedium,
          theme.textTheme.labelSmall,
        ];
        for (final style in styles) {
          expect(style?.letterSpacing, anyOf(0, isNull));
        }
      }
    });

    test('the bundled font assets are declared for both families', () {
      expect(AppConstants.fontFamily, 'Manrope');
      expect(AppConstants.fontFamilyFallback, ['Cairo']);
    });
  });
}
