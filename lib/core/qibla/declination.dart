/// Magnetic declination from the World Magnetic Model — pure Dart, no plugins.
///
/// The Qibla bearing is referenced to *true* north, while Android's compass
/// sensor reports azimuth relative to *magnetic* north. `geomag` ships the
/// WMM2025 coefficients and works offline, so correcting the heading needs no
/// network call, account or extra permission.
library;

import 'package:geomag/geomag.dart';

/// Singleton: parsing the coefficient table once keeps the per-location lookup
/// cheap, and the provider below caches the result until coordinates change.
final GeoMag _model = GeoMag();

/// Declination in degrees east of true north at [latitude]/[longitude].
///
/// [date] defaults to "now" so the WMM's yearly drift is reflected without a
/// app update; tests can pass a fixed instant for deterministic values.
double magneticDeclinationAt(
  double latitude,
  double longitude, {
  DateTime? date,
}) => _model.calculate(latitude, longitude, 0, date).dec;
