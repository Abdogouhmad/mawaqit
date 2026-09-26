import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/data/services/prayer_widget_service.dart';

/// Native background scheduling for daily re-computation and notification
/// (re)scheduling — resilient across reboots via WorkManager.
abstract final class BackgroundScheduler {
  static const String dailyRescheduleTask = 'com.mawaqit.dailyReschedule';

  /// One-off task enqueued by the native `BootReceiver` after a reboot or an
  /// in-place update. Must stay in step with `BootRescheduleWork.TASK_NAME`:
  /// the isolate dispatches on the name it is handed.
  static const String bootRescheduleTask = 'com.mawaqit.bootReschedule';

  static void initialize() {
    // WorkManager only exists on Android/iOS; it would throw on desktop.
    if (!_supportsWorkmanager) return;
    try {
      Workmanager().initialize(callbackDispatcher);
    } catch (_) {}
  }

  static bool get _supportsWorkmanager =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> registerDailyReschedule() async {
    await Workmanager().registerPeriodicTask(
      dailyRescheduleTask,
      dailyRescheduleTask,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  /// Standalone recompute + reschedule run inside the background isolate.
  static Future<bool> rescheduleAll() async {
    try {
      final settings = await SettingsRepository().load();
      final cached = await LocationRepository.cached();
      if (cached == null) return false;

      final day = _dayFor(cached, settings);
      final notifications = NotificationService.instance;
      // Read-only: the background isolate has no activity behind it, so a
      // permission dialog could stall (or throw) and take the whole reschedule
      // down with it.
      await notifications.init(allowPrompt: false);
      await notifications.scheduleDay(day, settings);
      await PrayerWidgetService.sync(
        day,
        settings,
        locationShort: cached.displayName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Immediate recompute + reschedule used after a settings / mute change so
  /// the new lead-time, tone or mute state applies without waiting for the
  /// next daily task — and after a system permission is granted, so the day's
  /// alarms are armed with the access the user just enabled.
  static Future<bool> rescheduleNow(AppSettings settings) async {
    try {
      final cached = await LocationRepository.cached();
      if (cached == null) return false;

      final day = _dayFor(cached, settings);
      final notifications = NotificationService.instance;
      await notifications.init(allowPrompt: false);
      await notifications.scheduleDay(day, settings);
      await PrayerWidgetService.sync(
        day,
        settings,
        locationShort: cached.displayName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static PrayerDay _dayFor(ResolvedLocation cached, AppSettings settings) {
    return PrayerTimesRepository().forDate(
      date: DateTime.now(),
      latitude: cached.latitude,
      longitude: cached.longitude,
      parameters: settings.parameters,
    );
  }
}

/// Entry point executed by WorkManager on the background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Both tasks do the same thing — recompute today and re-arm it. The boot
    // one is not a separate behaviour, only a separate reason to run: a reboot
    // or an update empties AlarmManager, and this is the soonest chance to fill
    // it back in (the periodic task can be half a day away).
    if (task == BackgroundScheduler.dailyRescheduleTask ||
        task == BackgroundScheduler.bootRescheduleTask) {
      return BackgroundScheduler.rescheduleAll();
    }
    return true;
  });
}
