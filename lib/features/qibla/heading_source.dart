import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One compass sample. A null [heading] means "no usable sensor reading"; it is
/// a first-class value, not an error, because desktop and test hosts genuinely
/// have no magnetometer and must degrade honestly rather than throw.
@immutable
class HeadingReading {
  const HeadingReading({this.heading, this.accuracy});

  final double? heading;

  /// Estimated error in degrees, when the platform reports one. Android's
  /// plugin uses coarse buckets (15/30/45); values at or above 45 mean the user
  /// should calibrate.
  final double? accuracy;

  bool get hasHeading => heading != null && heading!.isFinite;

  /// Whether the platform's accuracy bucket asks the user to calibrate.
  bool get needsCalibration => accuracy != null && accuracy! >= 45;
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
/// that points nowhere. Missing plugin channels and stream errors are swallowed
/// rather than allowed to crash the tab.
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

    await for (final event in events.handleError((_) {})) {
      yield HeadingReading(heading: event.heading, accuracy: event.accuracy);
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
