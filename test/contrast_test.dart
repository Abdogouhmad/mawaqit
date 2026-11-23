import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';

/// WCAG 2.2 relative luminance and contrast ratio for the opaque scheme roles
/// the UI uses as text. Kept here rather than in `lib/` because nothing in the
/// app needs to compute contrast at runtime — this is a release gate.
double _luminance(Color color) {
  final argb = color.toARGB32();
  double channel(int value) {
    final s = value / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((argb >> 16) & 0xFF) +
      0.7152 * channel((argb >> 8) & 0xFF) +
      0.0722 * channel(argb & 0xFF);
}

double contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // WCAG AA for normal text. Large text (≥24px, or ≥18.6px bold) only needs
  // 3:1, so checking everything at 4.5 leaves headroom and keeps the report
  // simple. The lowest observed pair is asserted separately below.
  const double aa = 4.5;

  for (final palette in AppPalette.values) {
    for (final dark in [false, true]) {
      for (final amoled in [false, true]) {
        if (amoled && !dark) continue;
        test('${palette.name} ${dark ? 'dark' : 'light'} '
            '${amoled ? 'AMOLED' : 'standard'} meets AA', () {
          final scheme =
              (dark
                      ? AppTheme.dark(palette: palette, amoled: amoled)
                      : AppTheme.light(palette: palette))
                  .colorScheme;

          final pairs = <String, double>{
            'onPrimary/primary': contrast(scheme.onPrimary, scheme.primary),
            'onSurface/surface': contrast(scheme.onSurface, scheme.surface),
            'onSurfaceVariant/surface': contrast(
              scheme.onSurfaceVariant,
              scheme.surface,
            ),
            'onPrimaryContainer/primaryContainer': contrast(
              scheme.onPrimaryContainer,
              scheme.primaryContainer,
            ),
            'onSecondaryContainer/secondaryContainer': contrast(
              scheme.onSecondaryContainer,
              scheme.secondaryContainer,
            ),
            'onTertiaryContainer/tertiaryContainer': contrast(
              scheme.onTertiaryContainer,
              scheme.tertiaryContainer,
            ),
            'onError/error': contrast(scheme.onError, scheme.error),
            'onSurface/surfaceContainerLowest': contrast(
              scheme.onSurface,
              scheme.surfaceContainerLowest,
            ),
            'primary/surface': contrast(scheme.primary, scheme.surface),
            'tertiary/surface': contrast(scheme.tertiary, scheme.surface),
          };

          for (final entry in pairs.entries) {
            expect(
              entry.value,
              greaterThanOrEqualTo(aa),
              reason: '${entry.key} is ${entry.value.toStringAsFixed(2)}:1',
            );
          }
        });
      }
    }
  }

  test('the app canvas colours themselves are the documented tokens', () {
    // Guards against someone "fixing" a contrast failure by changing the test
    // fixture rather than the palette.
    expect(AppColors.canvasLight.toARGB32(), 0xFFFAFAF7);
    expect(AppColors.canvasDark.toARGB32(), 0xFF0B1512);
    expect(AppColors.amoledSurface.toARGB32(), 0xFF000000);
  });
}
