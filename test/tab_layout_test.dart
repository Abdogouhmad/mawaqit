import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/core/navigation/app_router.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Layout regression test for every tab, driven through the real router.
///
/// A `RenderFlex overflowed by 21 pixels on the right` was reported on a device
/// but could not be pinned to a tab from a bug report. Width and locale are the
/// two axes that decide whether a `Text` fits, so both are swept here across the
/// narrowest common phone and the width the report came from — in all three
/// supported locales, so a fix cannot silently hold for English only.
///
/// The failure mode this guards against is specific and easy to reintroduce: a
/// `Text` (or [UiText]) placed as a direct child of a `Row` is handed an
/// unbounded main-axis width, lays out at its full intrinsic width, and silently
/// paints past the card. `Flexible` is what prevents it.
void main() {
  final now = DateTime.now();

  final home = HomeState(
    now: now,
    locationName: 'Raleigh, NC',
    latitude: 35.7750,
    longitude: -78.6336,
    day: PrayerDay(
      date: DateTime(now.year, now.month, now.day),
      prayers: PrayerKind.five
          .map(
            (k) => PrayerTime(
              kind: k,
              time: DateTime(now.year, now.month, now.day, 5),
            ),
          )
          .toList(),
      sunrise: DateTime(now.year, now.month, now.day, 6),
      sunset: DateTime(now.year, now.month, now.day, 18),
      solarNoon: DateTime(now.year, now.month, now.day, 12),
      nextDayFajr: DateTime(now.year, now.month, now.day + 1, 5),
      methodName: 'North America',
    ),
  );

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final tab in AppRoutes.tabs) {
        testWidgets(
          '${tab == '/' ? 'home' : tab} lays out at ${width.toInt()}dp in ${locale.languageCode}',
          (tester) async {
            tester.view.physicalSize = Size(width, 780) * 3;
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            SharedPreferences.setMockInitialValues({});

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  homeControllerProvider.overrideWith(() => _StubHome(home)),
                ],
                child: MaterialApp.router(
                  routerConfig: createRouter(initialLocation: tab),
                  theme: AppTheme.light(),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                ),
              ),
            );
            await tester.pumpAndSettle();

            // `takeException` returns the overflow rather than letting it escape as
            // a framework error, so assert on it explicitly: an unhandled overflow
            // would otherwise fail the test with a far less actionable message.
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'overflow on $tab at ${width.toInt()}dp in ${locale.languageCode}',
            );
          },
        );
      }
    }
  }

  // Times only, because it is the only tab whose columns are fixed-width: five
  // prayer times share whatever the date cell leaves over. Every other tab stacks
  // or wraps, so scaling the font cannot overflow it. Swept at 200% because that
  // is where a fixed-width column runs out of room — the highlighted row also
  // spends ~13dp on its border, margins and accent bar, which is exactly the
  // margin the layout had before the scale change.
  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.5, 2.0]) {
        testWidgets(
          'times lays out at ${width.toInt()}dp in ${locale.languageCode} at ${scale}x text',
          (tester) async {
            tester.view.physicalSize = Size(width, 780) * 3;
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            SharedPreferences.setMockInitialValues({});

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  homeControllerProvider.overrideWith(() => _StubHome(home)),
                ],
                child: MaterialApp.router(
                  routerConfig: createRouter(initialLocation: '/times'),
                  theme: AppTheme.light(),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'overflow on /times at ${width.toInt()}dp in '
                  '${locale.languageCode} at ${scale}x text',
            );
          },
        );
      }
    }
  }
}

/// Minimal [HomeController] stand-in: the tabs only read the resolved
/// coordinates off `HomeState`, so overriding the notifier avoids standing up the
/// location repository and the whole alarm pipeline behind it.
class _StubHome extends HomeController {
  _StubHome(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;
}

