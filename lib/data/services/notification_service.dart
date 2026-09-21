import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

/// Schedules prayer reminders (custom RemoteViews card on Android) and adhan
/// alarms at exact prayer entry.
///
/// The richer lockscreen card with progress bar + quick actions is rendered by
/// native code via `mawaqit/native` MethodChannel. A plain flutter
/// notification is used as a reliable fallback when the native side is
/// unreachable (e.g. background isolate during boot reschedule).
class NotificationService {
  NotificationService();

  static const String _nativeChannel = 'mawaqit/native';

  // Flutter notification id spaces.
  static const int _adhanIdBase = 100; // exact-entry adhan alarms
  static const int _reminderIdBase = 200; // plain reminder fallback

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final MethodChannel _channel = const MethodChannel(_nativeChannel);

  bool? _exactAlarmGranted;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await TimezoneSetup.ensureInitialized();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_waqt'),
      ),
    );

    // Runtime permissions (Android 13+).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _exactAlarmGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  bool get canUseExactAlarms => _exactAlarmGranted ?? false;

  /// (Re)schedules all notifications for [day] based on [settings].
  Future<void> scheduleDay(PrayerDay day, AppSettings settings) async {
    await cancelAll();

    try {
      await _scheduleAdhanAlarms(day, settings);
    } catch (_) {}

    if (settings.leadMinutes <= 0) return;
    final reminders = _buildReminders(day, settings.leadMinutes);

    // Preferred: native decorated card.
    try {
      await _channel.invokeMethod('scheduleReminders', {
        'reminders': reminders,
        'sunriseMs': _nextSunrise(day).millisecondsSinceEpoch,
        'fajrMs': _nextFajr(day).millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      // Fallback: plain flutter reminders (works in background isolates).
      await _scheduleFlutterReminders(reminders);
    } catch (_) {
      await _scheduleFlutterReminders(reminders);
    }
  }

  /// Upcoming sunrise (rolls to tomorrow once today's has passed).
  DateTime _nextSunrise(PrayerDay day) {
    final now = DateTime.now();
    return day.sunrise.isAfter(now)
        ? day.sunrise
        : day.sunrise.add(const Duration(days: 1));
  }

  /// Upcoming Fajr (today's if still ahead, else the next day's).
  DateTime _nextFajr(PrayerDay day) {
    final now = DateTime.now();
    final today = day.prayer(PrayerKind.fajr)?.time;
    if (today != null && today.isAfter(now)) return today;
    return day.nextDayFajr;
  }

  List<Map<String, dynamic>> _buildReminders(
    PrayerDay day,
    int leadMinutes,
  ) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < day.prayers.length; i++) {
      final p = day.prayers[i];
      final at = p.time.subtract(Duration(minutes: leadMinutes));
      if (at.isAfter(DateTime.now())) {
        result.add({
          'id': 300 + i,
          'name': p.kind.displayName,
          'timestampMs': at.millisecondsSinceEpoch,
          'prayerTimestampMs': p.time.millisecondsSinceEpoch,
          'leadMinutes': leadMinutes,
        });
      }
    }
    return result;
  }

  Future<void> _scheduleAdhanAlarms(PrayerDay day, AppSettings settings) async {
    if (!settings.adhanSoundEnabled) return;
    if (!canUseExactAlarms) return;

    // Android 8+ binds sound to the channel, so each distinct sound gets its
    // own channel id. Creating it here keeps the selected tone applied even
    // after the user changes it.
    final channel = _adhanChannel(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final now = DateTime.now();
    for (var i = 0; i < day.prayers.length; i++) {
      final p = day.prayers[i];
      if (!p.time.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _adhanIdBase + i,
        title: 'Adhan — ${p.kind.displayName}',
        body: 'It is now time for the ${p.kind.displayName} prayer.',
        scheduledDate: tz.TZDateTime.from(p.time, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: false,
            playSound: channel.playSound,
            sound: channel.sound,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: p.kind.name,
      );
    }
  }

  /// Builds the notification channel for the currently selected adhan sound.
  AndroidNotificationChannel _adhanChannel(AppSettings settings) {
    const name = 'Prayer time';
    const description = 'Plays the selected adhan when a prayer begins';

    if (settings.usesDeviceTone) {
      final device = DeviceTone(
        name: settings.adhanDeviceToneName ?? 'Device sound',
        uri: settings.adhanDeviceToneUri!,
      );
      return AndroidNotificationChannel(
        'mawaqit_adhan_dev_${device.slug}',
        name,
        description: description,
        importance: Importance.max,
        playSound: true,
        sound: UriAndroidNotificationSound(device.uri),
      );
    }

    final tone = ToneCatalog.byName(settings.adhanTone);
    if (tone.silent) {
      return const AndroidNotificationChannel(
        'mawaqit_adhan_silent',
        name,
        description: description,
        importance: Importance.max,
        playSound: false,
      );
    }

    return AndroidNotificationChannel(
      'mawaqit_adhan_${tone.androidRawResource}',
      name,
      description: description,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(tone.androidRawResource),
    );
  }

  Future<void> _scheduleFlutterReminders(
    List<Map<String, dynamic>> reminders,
  ) async {
    if (!canUseExactAlarms) return;
    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final when = DateTime.fromMillisecondsSinceEpoch(
        r['timestampMs'] as int,
      );
      await _plugin.zonedSchedule(
        id: _reminderIdBase + i,
        title: '${r['name']} in a few minutes',
        body: 'Adhan follows shortly.',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'mawaqit_reminders',
            'Reminders',
            channelDescription: 'Pre-prayer countdown reminders',
            importance: Importance.defaultImportance,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: r['name'] as String?,
      );
    }
  }

  Future<void> cancelAll() async {
    await _cancelFlutter();
    try {
      await _channel.invokeMethod('cancelReminders');
    } catch (_) {}
  }

  Future<void> _cancelFlutter() async {
    for (var i = 0; i < 5; i++) {
      await _plugin.cancel(id: _adhanIdBase + i);
      await _plugin.cancel(id: _reminderIdBase + i);
    }
  }
}