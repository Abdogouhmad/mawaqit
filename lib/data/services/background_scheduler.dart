import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';
import 'package:mawaqit/data/services/notification_service.dart';
import 'package:mawaqit/data/services/widget_service.dart';

/// Native background scheduling for daily re-computation and notification
/// (re)scheduling — resilient across reboots via WorkManager.
abstract final class BackgroundScheduler {
  static const String dailyRescheduleTask = 'com.mawaqit.dailyReschedule';

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
      await notifications.init();
      await notifications.scheduleDay(day, settings);
      await pushWidget(day);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Immediate recompute + reschedule used after a settings / mute change so
  /// the new lead-time, tone or mute state applies without waiting for the
  /// next daily task.
  static Future<bool> rescheduleNow(AppSettings settings) async {
    try {
      final cached = await LocationRepository.cached();
      if (cached == null) return false;

      final day = _dayFor(cached, settings);
      final notifications = NotificationService.instance;
      await notifications.init();
      await notifications.scheduleDay(day, settings);
      await pushWidget(day);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Refreshes the home-screen widget to the current "next prayer" snapshot.
  /// Called on the daily recompute and once after each prayer transition.
  static Future<void> pushWidget(PrayerDay day) async {
    final now = DateTime.now();
    final next = day.currentOrNextPrayer(now) ??
        PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
    final current = day.currentPrayer(now);
    await WidgetService.updateWidget(
      day: day,
      nextPrayer: next,
      currentPrayer: current,
      now: now,
    );
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
    if (task == BackgroundScheduler.dailyRescheduleTask) {
      return BackgroundScheduler.rescheduleAll();
    }
    return true;
  });
}