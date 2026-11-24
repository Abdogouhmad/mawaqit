import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/qibla/declination.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/qibla/heading_source.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';

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

  /// Device heading when a magnetometer supplied one, corrected to true north.
  final double? heading;

  final CompassStatus status;

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasNeedle => heading != null && bearing != null;

  /// Degrees the needle must rotate from screen-up to point at the Qibla.
  ///
  /// Positive values mean "turn right" (clockwise); negative means "turn left".
  double? get needleAngle =>
      hasNeedle ? qiblaNeedleAngle(bearing!, heading!) : null;

  /// Whether the screen may honestly say the user is facing the Qibla.
  ///
  /// A coarse or unknown sensor accuracy never counts: the needle may happen
  /// to be near the top, but the reading is not trustworthy enough to confirm
  /// alignment. Only the fully available state can report it.
  bool get isAligned =>
      status == CompassStatus.available &&
      needleAngle != null &&
      needleAngle!.abs() <= qiblaAlignmentTolerance;
}

/// Offline WMM lookup, cached per coordinate pair by Riverpod.
final magneticDeclinationProvider =
    Provider.family<double, ({double latitude, double longitude})>((
      ref,
      point,
    ) {
      return magneticDeclinationAt(point.latitude, point.longitude);
    });

/// Combines the effective prayer location with the compass stream.
///
/// Coordinates come from [AppSettings] first (travel override, then chosen city)
/// and from the resolved Home state only as a GPS fallback. Reading settings
/// directly matters: Home is recomputed asynchronously, so during travel the
/// old `HomeState` can briefly still hold the saved city and show a bearing to
/// the wrong place. A plain [Provider] is enough — both inputs are already
/// reactive, and neither needs a mutable notifier of its own.
final qiblaControllerProvider = Provider<QiblaState>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final home = ref.watch(homeControllerProvider).value;
  final reading = ref.watch(headingProvider).value ?? const HeadingReading();

  final fromSettings =
      settings?.effectiveLatitude != null &&
      settings?.effectiveLongitude != null;
  final latitude = fromSettings ? settings!.effectiveLatitude : home?.latitude;
  final longitude = fromSettings
      ? settings!.effectiveLongitude
      : home?.longitude;
  final locationName = fromSettings
      ? (settings!.effectiveLocationName ?? home?.locationName ?? '')
      : (home?.locationName ?? '');

  final hasLocation = latitude != null && longitude != null;

  final CompassStatus status = !reading.hasHeading
      ? CompassStatus.unavailable
      : reading.needsCalibration
      ? CompassStatus.calibrating
      : CompassStatus.available;

  // Android reports magnetic azimuth; convert it into the same true-north frame
  // the great-circle bearing uses. True-north readings only need normalising
  // (Android can emit −180…180, iOS 0…360).
  final declination = hasLocation
      ? ref.watch(
          magneticDeclinationProvider((
            latitude: latitude,
            longitude: longitude,
          )),
        )
      : 0.0;
  final heading = switch (reading.hasHeading) {
    false => null,
    true when reading.basis == HeadingBasis.magneticNorth =>
      magneticToTrueHeading(reading.heading!, declination),
    true => normalizeAzimuth(reading.heading!),
  };

  return QiblaState(
    locationName: locationName,
    latitude: latitude,
    longitude: longitude,
    bearing: hasLocation ? qiblaBearing(latitude, longitude) : null,
    distanceKm: hasLocation ? qiblaDistanceKm(latitude, longitude) : null,
    heading: heading,
    status: status,
  );
});
