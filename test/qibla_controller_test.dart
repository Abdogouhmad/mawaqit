import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/qibla/heading_source.dart';
import 'package:mawaqit/features/qibla/qibla_controller.dart';

void main() {
  final home = HomeState(
    now: DateTime(2026),
    latitude: 34.0209,
    longitude: -6.8416,
    locationName: 'Rabat',
  );

  Future<QiblaState> pumpState(tester, Stream<HeadingReading> heading) async {
    late QiblaState result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith(() => _StubHome(home)),
          headingProvider.overrideWith((_) => heading),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final ready =
                ref.watch(homeControllerProvider).hasValue &&
                ref.watch(headingProvider).hasValue;
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
}

class _StubHome extends HomeController {
  _StubHome(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;
}
