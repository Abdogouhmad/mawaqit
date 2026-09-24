import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Initialises the IANA timezone database exactly once per isolate and pins
/// `tz.local` to the device timezone (needed by zoned notifications).
abstract final class TimezoneSetup {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC when the platform name cannot be resolved.
    }
    _initialized = true;
  }
}
