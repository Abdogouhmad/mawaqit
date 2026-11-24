import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/qibla/travel_screen.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Travel joined the visual contract in 1.1.0: the search field, active-override
/// card and return action must fit 360/388dp in every locale at 200% text.
void main() {
  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 2.0]) {
        for (final traveling in [true, false]) {
          testWidgets('Travel at ${width.toInt()}dp in ${locale.languageCode} '
              'at ${scale}x, traveling=$traveling', (tester) async {
            tester.view.physicalSize = Size(width, 9000) * 3;
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            final settings = traveling
                ? const AppSettings(
                    travelName: 'Makkah',
                    travelLatitude: 21.4225,
                    travelLongitude: 39.8262,
                  )
                : const AppSettings();

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  settingsProvider.overrideWith(() => _StubSettings(settings)),
                ],
                child: MaterialApp(
                  theme: AppTheme.dark(arabic: locale.languageCode == 'ar'),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const TravelScreen(),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            final l10n = AppLocalizations.of(
              tester.element(find.byType(TravelScreen)),
            );
            expect(find.text(l10n.travelSetLocation), findsWidgets);
            expect(
              find.text(traveling ? l10n.travelReturn : l10n.travelSearchHint),
              findsWidgets,
            );
          });
        }
      }
    }
  }
}

class _StubSettings extends SettingsController {
  _StubSettings(this._state);

  final AppSettings _state;

  @override
  Future<AppSettings> build() async => _state;
}
