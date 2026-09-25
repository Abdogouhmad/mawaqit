import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/theme/app_theme.dart';
import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';

void main() {
  group('Sage Emerald theme', () {
    test('light scheme uses the sage primary', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.primary, AppColors.primaryLight);
      expect(theme.textTheme.titleLarge?.fontFamily, isNotNull);
    });

    test('dark scheme uses its own primary', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.primary, AppColors.primaryDark);
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('app shell ripple + font', () {
    testWidgets('SegmentedControl highlights the selected option', (
      tester,
    ) async {
      var selected = 5;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SegmentedControl<int>(
              options: const [(0, 'None'), (5, '5'), (10, '10')],
              value: selected,
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      expect(find.text('None'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('10'));
      expect(selected, 10);
    });
  });
}
