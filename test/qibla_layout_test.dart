import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/qibla/heading_source.dart';
import 'package:mawaqit/features/qibla/qibla_screen.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// The Qibla tab joined the visual contract in 1.1.0: 360/388dp, all locales,
/// 200% text, both with a live needle and with the sensor-unavailable fallback.
/// No goldens — overflow and wrong states fail the test instead.
void main() {
  final home = HomeState(
    now: DateTime(2026),
    latitude: 34.0209,
    longitude: -6.8416,
    locationName: 'Rabat',
  );

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 2.0]) {
        for (final hasSensor in [true, false]) {
          testWidgets('Qibla at ${width.toInt()}dp in ${locale.languageCode} '
              'at ${scale}x, sensor=$hasSensor', (tester) async {
            await pumpQibla(
              tester,
              home,
              locale,
              width,
              scale,
              hasSensor: hasSensor,
            );
            expect(tester.takeException(), isNull);

            final l10n = AppLocalizations.of(
              tester.element(find.byType(QiblaScreen)),
            );
            expect(find.text(l10n.qiblaTitle), findsWidgets);
            expect(
              find.text(
                hasSensor ? l10n.qiblaCompassHint : l10n.qiblaSensorUnavailable,
              ),
              findsOneWidget,
            );
          });
        }
      }
    }
  }

  testWidgets('dial semantics announce the bearing and sensor state', (
    tester,
  ) async {
    await pumpQibla(tester, home, const Locale('en'), 360, 1, hasSensor: true);
    final l10n = AppLocalizations.of(tester.element(find.byType(QiblaScreen)));
    final semantics = tester.ensureSemantics();
    await tester.pumpAndSettle();
    final bearingLabel = l10n.qiblaBearing(
      qiblaBearing(34.0209, -6.8416).round().toString(),
    );

    expect(
      find.semantics.byLabel('$bearingLabel, ${l10n.qiblaCompassHint}'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Future<void> pumpQibla(
  WidgetTester tester,
  HomeState home,
  Locale locale,
  double width,
  double scale, {
  required bool hasSensor,
}) async {
  tester.view.physicalSize = Size(width, 9000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final heading = hasSensor
      ? Stream.value(const HeadingReading(heading: 140, accuracy: 15))
      : Stream.value(const HeadingReading());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeControllerProvider.overrideWith(() => _StubHome(home)),
        settingsProvider.overrideWith(() => _StubSettings(const AppSettings())),
        headingProvider.overrideWith((_) => heading),
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
        home: const QiblaScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StubHome extends HomeController {
  _StubHome(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;
}

class _StubSettings extends SettingsController {
  _StubSettings(this._state);

  final AppSettings _state;

  @override
  Future<AppSettings> build() async => _state;
}
