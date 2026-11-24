/// Pure Qibla maths — no Flutter, no plugins, no locale.
///
/// The bearing is the initial great-circle heading from the observer to the
/// Kaaba. Keeping the trigonometry here means the same numbers drive the live
/// compass, the sensor-unavailable fallback and the unit tests, including the
/// antimeridian cases that a naive longitude subtraction gets wrong.
library;

import 'dart:math' as math;

/// Coordinates of the Kaaba in Mecca.
const qiblaLatitude = 21.4225;
const qiblaLongitude = 39.8262;

/// Great-circle distance to the Qibla, in kilometres.
double qiblaDistanceKm(double latitude, double longitude) {
  final phi1 = _radians(latitude);
  final phi2 = _radians(qiblaLatitude);
  final dPhi = phi2 - phi1;
  final dLambda = _radians(_normalizeLongitude(qiblaLongitude - longitude));

  final a =
      math.pow(math.sin(dPhi / 2), 2) +
      math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
  return 2 * 6371.0 * math.asin(math.sqrt(a.clamp(0, 1).toDouble()));
}

/// Initial bearing to the Qibla, in degrees clockwise from true north (0–360).
///
/// `atan2` already keeps the result in the correct quadrant; only the longitude
/// difference needs wrapping so crossing ±180° takes the short way round.
double qiblaBearing(double latitude, double longitude) {
  final phi1 = _radians(latitude);
  final phi2 = _radians(qiblaLatitude);
  final dLambda = _radians(_normalizeLongitude(qiblaLongitude - longitude));

  final y = math.sin(dLambda) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
  return _azimuth(_degrees(math.atan2(y, x)));
}

/// Degrees the compass arrow must rotate to point at the Qibla.
///
/// Both inputs are clockwise-from-**true**-north degrees. The result is
/// normalised to −180…180 so the needle always takes the shorter turn.
double qiblaNeedleAngle(double bearing, double heading) =>
    shortestAngleDelta(heading, bearing);

/// Signed shortest turn from [from] to [to], in −180…180 degrees.
double shortestAngleDelta(double from, double to) =>
    _normalizeSigned(to - from);

/// Converts a magnetic-north heading into a true-north heading.
///
/// Magnetic declination is positive east of true north, so a compass reading
/// [magnetic] points [declination] degrees to the east of where true north is;
/// adding it back puts both the heading and [qiblaBearing] in the same frame.
/// Android sensors report magnetic azimuth, iOS reports `trueHeading` — this is
/// what keeps the needle consistent across platforms.
double magneticToTrueHeading(double magnetic, double declination) =>
    _azimuth(magnetic + declination);

/// Wraps any azimuth into 0…360. Android's `getOrientation` returns −180…180;
/// this puts it in the same frame as the computed Qibla bearing.
double normalizeAzimuth(double degrees) => _azimuth(degrees);

/// Wrap-safe angular low-pass filter for a noisy compass stream.
///
/// A plain `(a + b) / 2` spins the needle the long way round when a sample
/// crosses north (359° → 1°). Taking the shortest signed delta first keeps the
/// correction continuous at the seam.
///
/// [alpha] is the weight of the new sample, 0…1: smaller is smoother but
/// laggier. Samples arrive around 30 Hz on Android, so 0.25 settles in roughly
/// a tenth of a second without feeling sticky.
double smoothHeading(double previous, double next, {double alpha = 0.25}) {
  final delta = _normalizeSigned(next - previous);
  return _azimuth(previous + alpha * delta);
}

double _radians(double degrees) => degrees * math.pi / 180;

double _degrees(double radians) => radians * 180 / math.pi;

/// Wraps a longitude difference into −180…180 degrees.
double _normalizeLongitude(double degrees) =>
    _normalizeSigned(degrees + 180) - 180;

double _normalizeSigned(double degrees) =>
    ((degrees + 180) % 360 + 360) % 360 - 180;

double _azimuth(double degrees) => (degrees % 360 + 360) % 360;
