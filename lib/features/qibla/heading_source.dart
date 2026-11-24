import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/qibla/qibla.dart';
import 'package:mawaqit/core/ui/theme/motion.dart';

/// North reference a sensor reading is measured against.
///
/// Android's `SensorManager.getOrientation` returns azimuth from **magnetic**
/// north; iOS's `CLHeading.trueHeading` is already from **true** north. The
/// Qibla bearing is true-north, so magnetic readings must be corrected before
/// they can drive the needle.
enum HeadingBasis { trueNorth, magneticNorth }

/// One compass sample. A null [heading] means "no usable sensor reading"; it is
/// a first-class value, not an error, because desktop and test hosts genuinely
/// have no magnetometer and must degrade honestly rather than throw.
@immutable
class HeadingReading {
  const HeadingReading({
    this.heading,
    this.accuracy,
    this.basis = HeadingBasis.trueNorth,
  });

  final double? heading;

  /// Estimated error in degrees, when the platform reports one. Android's
  /// plugin uses coarse buckets (15/30/45) and reports null while the sensor
  /// accuracy is unknown/unreliable — mapped to −1 below. Values at or above
  /// 45, or a negative "unknown", ask the user to calibrate.
  final double? accuracy;

  /// North reference of [heading]; defaults to true north so tests that inject
  /// a reading describe the final, corrected value.
  final HeadingBasis basis;

  bool get hasHeading => heading != null && heading!.isFinite;

  /// Whether the platform's accuracy asks the user to calibrate.
  bool get needsCalibration =>
      accuracy != null && (accuracy! < 0 || accuracy! >= 45);
}

/// The platform-independent seam the Qibla screen reads. Tests override
/// [headingSourceProvider] with a controller stream to drive available /
/// calibrating / unavailable states without a magnetometer.
abstract class HeadingSource {
  Stream<HeadingReading> read();
}

/// Default source backed by `flutter_compass`.
///
/// Emits an unavailable reading immediately, then replaces it with real samples
/// as they arrive. That gives an honest "sensor unavailable" state on desktop,
/// test hosts and stale installs without a timeout, and avoids showing a needle
/// that points nowhere.
///
/// Samples are wrapped through a low-pass filter (the plugin pushes ~30 events
/// a second) so the arrow glides instead of vibrating. A dropped channel is
/// retried rather than killing the source for the rest of the session.
class CompassHeadingSource implements HeadingSource {
  const CompassHeadingSource();

  @override
  Stream<HeadingReading> read() async* {
    yield const HeadingReading();

    Stream<CompassEvent>? events;
    try {
      events = FlutterCompass.events;
    } catch (_) {
      return; // No plugin registered (desktop, test host, stale install).
    }
    if (events == null) return; // Web has no magnetometer.
    var stream = events;

    final basis = defaultTargetPlatform == TargetPlatform.android
        ? HeadingBasis.magneticNorth
        : HeadingBasis.trueNorth;
    double? smoothed;

    while (true) {
      try {
        await for (final event in stream) {
          final raw = event.heading;
          final heading = switch (raw) {
            null => null,
            _ when !raw.isFinite => null,
            _ when smoothed == null => normalizeAzimuth(raw),
            _ => smoothHeading(smoothed, raw),
          };
          smoothed = heading;

          yield HeadingReading(
            heading: heading,
            // The plugin collapses Android's "unreliable" (-1) to null. Restore
            // it so the UI asks for calibration instead of trusting a bad fix.
            accuracy: basis == HeadingBasis.magneticNorth
                ? (event.accuracy ?? -1)
                : event.accuracy,
            basis: basis,
          );
        }
      } catch (_) {
        // Transient platform-channel error: drop the stale sample and retry.
      }

      smoothed = null;
      await Future<void>.delayed(AppMotion.retry);
      try {
        final next = FlutterCompass.events;
        if (next == null) return;
        stream = next;
      } catch (_) {
        return;
      }
    }
  }
}

final headingSourceProvider = Provider<HeadingSource>(
  (ref) => const CompassHeadingSource(),
);

/// Latest compass sample for the Qibla compass. Kept as a [StreamProvider] so
/// the subscription is shared, cancelled when nobody is listening, and trivially
/// overridden in widget tests.
final headingProvider = StreamProvider<HeadingReading>((ref) {
  return ref.watch(headingSourceProvider).read();
});
