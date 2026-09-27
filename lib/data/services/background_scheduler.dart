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

  /// Registers the periodic reschedule, at most once per process.
  ///
  /// `existingWorkPolicy: update` rewrites the stored schedule every time it
  /// runs, and this used to be called on every Home rebuild — so a settings tap
  /// would restart the 12h period from zero, which in practice meant the daily
  /// reschedule could be starved indefinitely on a frequently-used phone.
  /// `keep` is the correct policy anyway: the task is already registered with
  /// the same name, frequency and constraints, so there is nothing to update.
  ///
  /// The guard is per-process on purpose. WorkManager persists the task across
  /// launches, so re-registering on every cold start is pure churn.
  static bool _dailyTaskRegistered = false;

  static Future<void> registerDailyReschedule() async {
    if (!_supportsWorkmanager) return;
    if (_dailyTaskRegistered) return;
    _dailyTaskRegistered = true;
    try {
      await Workmanager().registerPeriodicTask(
        dailyRescheduleTask,
        dailyRescheduleTask,
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    } catch (error) {
      // Allow a later attempt (e.g. a transient platform-channel failure)
      // rather than leaving the app permanently unregistered for this process.
      _dailyTaskRegistered = false;
      debugPrint('registerDailyReschedule failed: $error');
    }
  }

  /// Standalone recompute + reschedule run inside the background isolate.
  static Future<bool> rescheduleAll() async {
    try {
      final settings = await SettingsRepository().load();
      final location = await _resolveLocation(settings);
      if (location == null) return false;

      final day = _dayFor(location, settings);
      final notifications = NotificationService.instance;
      // Read-only: the background isolate has no activity behind it, so a
      // permission dialog could stall (or throw) and take the whole reschedule
      // down with it.
      await notifications.init(allowPrompt: false);
      await notifications.scheduleDay(day, settings);
      await PrayerWidgetService.sync(
        day,
        settings,
        locationShort: location.displayName,
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
      final location = await _resolveLocation(settings);
      if (location == null) return false;

      final day = _dayFor(location, settings);
      final notifications = NotificationService.instance;
      await notifications.init(allowPrompt: false);
      await notifications.scheduleDay(day, settings);
      await PrayerWidgetService.sync(
        day,
        settings,
        locationShort: location.displayName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Coordinates a reschedule should compute for.
  ///
  /// A chosen city always wins over the cached GPS fix. The cache is only ever
  /// written on the GPS branch of `LocationRepository.resolve`, so this is the
  /// difference between working and silently broken for two whole classes of
  /// user: a city-only user has no cache at all (every reschedule used to bail
  /// out with `false`, leaving no alarms after a reboot), and a city user who
  /// once had a fix would otherwise have had alarms armed for wherever the phone
  /// was, quietly disagreeing with the times on the home screen.
  static Future<ResolvedLocation?> _resolveLocation(
    AppSettings settings,
  ) async {
    final coordinates = settings.effectiveCoordinates;
    if (coordinates != null) {
      return ResolvedLocation(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        displayName: settings.cityName ?? 'Selected city',
        fromManual: true,
      );
    }
    return LocationRepository.cached();
  }

  static PrayerDay _dayFor(ResolvedLocation location, AppSettings settings) {
    return PrayerTimesRepository().forDate(
      date: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
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
