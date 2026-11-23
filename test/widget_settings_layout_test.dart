import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/settings/screen/widget.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// The widget configuration screen is the longest new string surface of 0.22.
/// Its quick-action labels are pre-staged in all three catalogues and must not
/// overflow at 2x text in RTL.
void main() {
  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('widget settings at ${width.toInt()}dp in '
            '${locale.languageCode} at ${scale}x', (tester) async {
          tester.view.physicalSize = Size(width, 9000) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                settingsProvider.overrideWith(_StubSettings.new),
                homeControllerProvider.overrideWith(_StubHome.new),
              ],
              child: MaterialApp(
                theme: AppTheme.dark(arabic: locale.languageCode == 'ar'),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const Scaffold(body: WidgetSettingsScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(WidgetSettingsScreen)),
          );
          expect(find.text(l10n.widgetTitle), findsWidgets);
          expect(find.text(l10n.widgetOpenTimes), findsOneWidget);
          expect(find.text(l10n.widgetSilenceAdhan), findsOneWidget);
        });
      }
    }
  }
}

class _StubSettings extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}

class _StubHome extends HomeController {
  @override
  Future<HomeState> build() async => HomeState(now: DateTime(2026));
}
