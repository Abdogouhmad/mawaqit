import 'dart:io' show Platform;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import 'package:mawaqit/data/services/notification_service.dart';

/// Screen-off exact alarms, mirroring the Rakiz approach.
///
/// Android pauses `flutter_local_notifications` timers in Doze, so the "Test
/// Notification" never fired with the display off. The only path that reliably
/// wakes a sleeping device is an exact `AlarmManager` wakeup alarm. Like Rakiz,
/// that alarm is armed here with `android_alarm_manager_plus` and, when it
/// fires, runs a small background Flutter isolate that posts the adhan alert
/// immediately — even when the app is fully backgrounded or killed.
abstract final class AlarmService {
  /// Dedicated request code for the test alarm. Kept well away from the
  /// notification ids so it can never collide with scheduled prayer alerts.
  static const int _testAlarmId = 555_001;

  static bool _initialized = false;

  /// Initializes the AlarmManager plumbing. Safe to call repeatedly.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.initialize();
  }

  /// Fires a real adhan alarm [delay] from now — even with the screen off.
  ///
  /// Prefers an exact `RTC_WAKEUP` alarm (wakes the device at the exact time,
  /// through Doze via `allowWhileIdle`). When exact alarms were never granted,
  /// degrades to an inexact-but-still-wakeup alarm so the test never silently
  /// dies — mirroring how [`PrayerScheduler`] falls back for real reminders.
  ///
  /// Returns `false` on non-Android platforms (Linux desktop keeps the plain
  /// plugin path) or when the alarm could not be armed.
  static Future<bool> scheduleTest({
    Duration delay = const Duration(seconds: 3),
  }) async {
    if (!Platform.isAndroid) return false;
    await init();

    if (NotificationService.instance.canUseExactAlarms) {
      return AndroidAlarmManager.oneShotAt(
        DateTime.now().add(delay),
        _testAlarmId,
        _testAlarmCallback,
        // `exact` + `wakeup` wakes the device at the exact time; `allowWhileIdle`
        // also lets it fire through deep Doze so the alert survives screen-off.
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );
    }

    return AndroidAlarmManager.oneShot(
      delay,
      _testAlarmId,
      _testAlarmCallback,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  /// Background-isolate entry point invoked by the fired alarm.
  @pragma('vm:entry-point')
  static Future<void> _testAlarmCallback() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await NotificationService.instance.showAdhanAlarmFromBackground();
    } catch (_) {
      // Best-effort: a background post failure must never crash the isolate.
    }
  }
}