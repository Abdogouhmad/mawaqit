import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/qibla/heading_source.dart';

/// How much of the compass can be trusted right now.
enum CompassStatus { available, calibrating, unavailable }

/// Everything the Qibla screen renders, derived from two independent sources:
/// the resolved prayer location (pure maths) and the live heading (sensor).
@immutable
class QiblaState {
  const QiblaState({
    this.locationName = '',
    this.latitude,
    this.longitude,
    this.bearing,
    this.distanceKm,
    this.heading,
    this.status = CompassStatus.unavailable,
  });

  final String locationName;
  final double? latitude;
  final double? longitude;

  /// Initial great-circle bearing to the Kaaba, 0–360° clockwise from north.
  final double? bearing;

  /// Great-circle distance in kilometres.
  final double? distanceKm;

  /// Device heading when a magnetometer supplied one.
  final double? heading;

  final CompassStatus status;

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasNeedle => heading != null && bearing != null;

  /// Degrees the needle must rotate from screen-up to point at the Qibla.
  double? get needleAngle =>
      hasNeedle ? qiblaNeedleAngle(bearing!, heading!) : null;
}

/// Combines the resolved Home location with the compass stream. A plain
/// [Provider] is enough: both inputs are already reactive, and neither needs a
/// mutable notifier of its own.
final qiblaControllerProvider = Provider<QiblaState>((ref) {
  final home = ref.watch(homeControllerProvider).value;
  final reading = ref.watch(headingProvider).value ?? const HeadingReading();

  final latitude = home?.latitude;
  final longitude = home?.longitude;
  final hasLocation = latitude != null && longitude != null;

  final CompassStatus status = !reading.hasHeading
      ? CompassStatus.unavailable
      : reading.needsCalibration
      ? CompassStatus.calibrating
      : CompassStatus.available;

  return QiblaState(
    locationName: home?.locationName ?? '',
    latitude: latitude,
    longitude: longitude,
    bearing: hasLocation ? qiblaBearing(latitude, longitude) : null,
    distanceKm: hasLocation ? qiblaDistanceKm(latitude, longitude) : null,
    heading: reading.hasHeading ? reading.heading : null,
    status: status,
  );
});
