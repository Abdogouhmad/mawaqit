import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/qibla/heading_source.dart';
import 'package:mawaqit/features/qibla/qibla_controller.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';

void main() {
  final home = HomeState(
    now: DateTime(2026),
    latitude: 34.0209,
    longitude: -6.8416,
    locationName: 'Rabat',
  );

  Future<QiblaState> pumpState(
    tester,
    Stream<HeadingReading> heading, {
    AppSettings settings = const AppSettings(),
    double? declination,
  }) async {
    late QiblaState result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith(() => _StubHome(home)),
          settingsProvider.overrideWith(() => _StubSettings(settings)),
          headingProvider.overrideWith((_) => heading),
          if (declination != null)
            magneticDeclinationProvider.overrideWith(
              (ref, point) => declination,
            ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final ready =
                ref.watch(homeControllerProvider).hasValue &&
                ref.watch(headingProvider).hasValue &&
                ref.watch(settingsProvider).hasValue;
            if (ready) result = ref.watch(qiblaControllerProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('computes bearing from the resolved home location', (
    tester,
  ) async {
    final state = await pumpState(tester, Stream.value(const HeadingReading()));

    expect(state.locationName, 'Rabat');
    expect(state.bearing, closeTo(qiblaBearing(34.0209, -6.8416), 0.0001));
    expect(state.distanceKm, greaterThan(4000));
    expect(state.status, CompassStatus.unavailable);
    expect(state.hasNeedle, isFalse);
  });

  testWidgets('uses the live heading when a magnetometer supplies one', (
    tester,
  ) async {
    final state = await pumpState(
      tester,
      Stream.value(const HeadingReading(heading: 140, accuracy: 10)),
    );

    expect(state.status, CompassStatus.available);
    expect(state.heading, 140);
    expect(
      state.needleAngle,
      closeTo(qiblaNeedleAngle(state.bearing!, 140), 0.0001),
    );
  });

  testWidgets('shows calibration hint for a coarse accuracy bucket', (
    tester,
  ) async {
    final state = await pumpState(
      tester,
      Stream.value(const HeadingReading(heading: 90, accuracy: 45)),
    );

    expect(state.status, CompassStatus.calibrating);
    expect(state.hasNeedle, isTrue);
  });

  testWidgets('asks for calibration on Android unknown accuracy', (
    tester,
  ) async {
    final state = await pumpState(
      tester,
      Stream.value(const HeadingReading(heading: 90, accuracy: -1)),
    );

    expect(state.status, CompassStatus.calibrating);
  });

  testWidgets('uses travel coordinates immediately, without rewriting home', (
    tester,
  ) async {
    const travel = AppSettings(
      travelName: 'Makkah',
      travelLatitude: qiblaLatitude,
      travelLongitude: qiblaLongitude,
    );
    final state = await pumpState(
      tester,
      Stream.value(const HeadingReading()),
      settings: travel,
    );

    expect(state.locationName, 'Makkah');
    expect(state.latitude, qiblaLatitude);
    expect(state.longitude, qiblaLongitude);
    expect(state.distanceKm, closeTo(0, 0.01));
    expect(home.latitude, 34.0209); // the saved home fix is untouched
    expect(home.longitude, -6.8416);
  });

  testWidgets('converts a magnetic heading into a true-north bearing', (
    tester,
  ) async {
    final state = await pumpState(
      tester,
      Stream.value(
        const HeadingReading(
          heading: 100,
          accuracy: 15,
          basis: HeadingBasis.magneticNorth,
        ),
      ),
      declination: 10,
    );

    expect(state.heading, closeTo(110, 0.0001));
    expect(
      state.needleAngle,
      closeTo(qiblaNeedleAngle(state.bearing!, 110), 0.0001),
    );
  });

  testWidgets('normalises a true-north heading from a negative azimuth', (
    tester,
  ) async {
    final state = await pumpState(
      tester,
      Stream.value(const HeadingReading(heading: -10, accuracy: 15)),
    );

    expect(state.heading, closeTo(350, 0.0001));
  });
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
