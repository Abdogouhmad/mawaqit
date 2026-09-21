import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/muted_prayers_store.dart';

/// Which audible notification an alert belongs to.
///
/// Every notification is routed through a channel matching its type — the
/// pre-prayer alert (short chime / countdown card) and the adhan (full clip)
/// never share a channel, and mute state only dampens the adhan path.
enum NotificationType { preAlert, adhan }

/// Schedules prayer notifications with a single, platform-agnostic core.
///
/// Scheduling logic (times, ids, dedup, mute) lives here and is identical on
/// Android and Linux so the whole pipeline is verifiable on the Linux desktop
/// before packaging an APK. Only the *posting* differs and is hidden behind
/// [`_postAt`]: Android uses `zonedSchedule` with exact timers, Linux runs a
/// local timer that posts via the plugin's `show`.
///
/// Android-only details (exact-alarm permission, sound channels, the custom
/// RemoteViews card) are guarded by the platform checks in this file and live
/// behind the `mawaqit/native` MethodChannel for the native card.
class NotificationService {
  /// Single shared instance: the daily task, the home controller and settings
  /// changes must all cancel the *same* timer map on Linux, or old timers
  /// would survive a reschedule and double-fire alongside new ones.
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  static const String _nativeChannel = 'mawaqit/native';

  // Deterministic per-day id spaces. `epochDay * 10 + prayerIndex` keeps every
  // prayer's id unique across days without colliding between alert kinds.
  static const int _adhanBucket = 0;
  static const int _reminderBucket = 1_000_000;
  static const int _nativeCardBucket = 2_000_000;

  /// Debug-only id for the "Test notification in 10s" settings trigger.
  ///
  /// Must fit within a signed 32-bit integer — Android's [validateId] enforces
  /// this (max = 2^31-1 = 2,147,483,647). Kept well below the nativeCard bucket
  /// start (2_000_000) to avoid collisions with scheduled prayer ids.
  static const int _testNotificationId = 1_999_999;

  /// Pre-prayer alert channel: short chime card shown `leadMinutes` early.
  static const AndroidNotificationChannel preAlertChannel =
      AndroidNotificationChannel(
    'pre_prayer_alert_v2',
    'Pre-prayer alert',
    description: 'Countdown reminder before each prayer',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('pre_alert'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  /// Channel used for a muted adhan: the notification still appears but is
  /// silent (product default: show, don't play).
  static const AndroidNotificationChannel silentAdhanChannel =
      AndroidNotificationChannel(
    'prayer_adhan_silent_v2',
    'Prayer call (muted)',
    description: 'Adhan shown silently for a muted prayer occurrence',
    importance: Importance.low,
    playSound: false,
  );

  /// Default adhan channel per the FIX-2 spec (full adhan clip). The concrete
  /// channel id is derived from the selected tone (`prayer_adhan_v2_*`) so
  /// channels stay distinct after the old single-sound config.
  static const AndroidNotificationChannel adhanChannel =
      AndroidNotificationChannel(
    'prayer_adhan_v2',
    'Prayer call (adhan)',
    description: 'Plays the adhan clip at prayer entry',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('adhan'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final MethodChannel _channel = const MethodChannel(_nativeChannel);
  final Map<int, Timer> _timers = {};
  final MutedPrayersStore _mutedStore = MutedPrayersStore();

  bool _initialized = false;
  bool _exactAlarmGranted = false;
  bool _notificationsGranted = false;

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await TimezoneSetup.ensureInitialized();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_mawaqit'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
    );

    if (_isAndroid) {
      // Runtime POST_NOTIFICATIONS (Android 13+) before the first schedule.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      _notificationsGranted =
          await android?.requestNotificationsPermission() ?? false;
      _exactAlarmGranted =
          await android?.requestExactAlarmsPermission() ?? false;
    }
  }

  /// Re-asks POST_NOTIFICATIONS and (API 31–32) exact-alarm access — surfaced
  /// from Settings so a first-launch denial can be undone without reinstalling.
  Future<bool> ensurePermissions() async {
    if (!_isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    _notificationsGranted =
        await android?.requestNotificationsPermission() ?? false;
    _exactAlarmGranted = await android?.requestExactAlarmsPermission() ?? false;
    return hasNotificationPermission;
  }

  bool get canUseExactAlarms => _isAndroid && _exactAlarmGranted;
  bool get hasNotificationPermission => !_isAndroid || _notificationsGranted;

  /// (Re)schedules all notifications for [day]. Always cancels what was left
  /// over from a previous run first so stale entries can never double-fire.
  Future<void> scheduleDay(PrayerDay day, AppSettings settings) async {
    await cancelAll();

    await _scheduleAdhanAlarms(day, settings);
    if (settings.leadMinutes <= 0) return;

    if (_isAndroid && canUseExactAlarms && hasNotificationPermission) {
      // Preferred Android path: native decorated countdown card. Requires exact
      // alarms (AlarmManager) and notification access; otherwise fall through
      // to the plain-flutter reminders below.
      try {
        await _channel.invokeMethod('scheduleReminders', {
          'reminders': _buildReminders(day, settings.leadMinutes),
          'sunriseMs': _nextSunrise(day).millisecondsSinceEpoch,
          'fajrMs': _nextFajr(day).millisecondsSinceEpoch,
          'sunsetMs': day.sunset.millisecondsSinceEpoch,
          'channelSound': _preAlertRawResource(settings),
        });
        return;
      } on MissingPluginException {
        // Fall through to the plain-flutter reminders.
      } catch (_) {
        // Fall through to the plain-flutter reminders.
      }
    }

    await _scheduleFlutterReminders(
      _buildReminders(day, settings.leadMinutes),
      settings,
    );
  }

  /// Debug trigger (settings): fires the pre-prayer alert card immediately
  /// on Android (with live countdown, synchronized progress bar, quick actions,
  /// and ambient footer matching Stitch) or schedules a 10s alert on desktop.
  Future<bool> scheduleTestNotification({
    AppSettings? settings,
    PrayerDay? day,
  }) async {
    if (_isAndroid && hasNotificationPermission) {
      try {
        final currentSettings = settings ?? const AppSettings();
        final leadMin = currentSettings.leadMinutes > 0 ? currentSettings.leadMinutes : 10;
        final now = DateTime.now();
        final nextPrayer = day?.currentOrNextPrayer(now);
        final prayerName = nextPrayer?.kind.displayName ?? 'Maghrib';

        final prayerMs = now.add(Duration(minutes: leadMin)).millisecondsSinceEpoch;
        final sunriseMs = day != null ? _nextSunrise(day).millisecondsSinceEpoch : 0;
        final fajrMs = day != null ? _nextFajr(day).millisecondsSinceEpoch : 0;
        final sunsetMs = day?.sunset.millisecondsSinceEpoch ?? 0;

        await _channel.invokeMethod('showTestReminder', {
          'id': _testNotificationId,
          'name': prayerName,
          'prayerId': day != null
              ? prayerIdFor(day.date, nextPrayer?.kind ?? PrayerKind.maghrib)
              : 'test_maghrib',
          'leadMinutes': leadMin,
          'prayerTimestampMs': prayerMs,
          'sunriseMs': sunriseMs,
          'fajrMs': fajrMs,
          'sunsetMs': sunsetMs,
          'channelSound': _preAlertRawResource(currentSettings),
        });
        return true;
      } catch (e, st) {
        debugPrint('Native test notification failed: $e\n$st');
        // Fall through to plain Flutter notification if method channel fails
      }
    }

    try {
      await _postAt(
        id: _testNotificationId,
        title: 'Test pre-prayer alert',
        body: 'This is a test. The adhan would follow shortly.',
        at: DateTime.now().add(const Duration(seconds: 10)),
        type: NotificationType.preAlert,
        muted: false,
        payload: 'test_pre_alert',
      );
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
      rethrow;
    }
    return true;
  }

  /// Human-readable id for one prayer occurrence, e.g. `"2026-09-21_maghrib"`.
  static String prayerIdFor(DateTime date, PrayerKind kind) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-${d}_${kind.name}';
  }

  Future<void> _scheduleAdhanAlarms(
    PrayerDay day,
    AppSettings settings,
  ) async {
    if (!settings.adhanSoundEnabled) return;
    if (!hasNotificationPermission) return;

    final muted = await _mutedStore.load();
    final now = DateTime.now();
    for (var i = 0; i < day.prayers.length; i++) {
      final p = day.prayers[i];
      if (!p.time.isAfter(now)) continue;

      final prayerId = prayerIdFor(day.date, p.kind);
      await _postAt(
        id: _adhanId(day.date, i),
        title: 'Adhan — ${p.kind.displayName}',
        body: 'It is now time for the ${p.kind.displayName} prayer.',
        at: p.time,
        type: NotificationType.adhan,
        settings: settings,
        muted: muted.contains(prayerId),
        payload: p.kind.name,
      );
    }
  }

  List<Map<String, dynamic>> _buildReminders(
    PrayerDay day,
    int leadMinutes,
  ) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < day.prayers.length; i++) {
      final p = day.prayers[i];
      // Offset is SUBTRACTED from the prayer time — the only place the lead is
      // applied, so rescheduling (daily task or settings change) can never
      // double-apply it.
      final at = p.time.subtract(Duration(minutes: leadMinutes));
      if (at.isAfter(DateTime.now())) {
        result.add({
          'id': _nativeCardId(day.date, i),
          'prayerId': prayerIdFor(day.date, p.kind),
          'name': p.kind.displayName,
          'timestampMs': at.millisecondsSinceEpoch,
          'prayerTimestampMs': p.time.millisecondsSinceEpoch,
          'leadMinutes': leadMinutes,
        });
      }
    }
    return result;
  }

  /// Plain (non-decorated) reminder used on Linux and as the Android fallback
  /// when the native card is unavailable.
  Future<void> _scheduleFlutterReminders(
    List<Map<String, dynamic>> reminders,
    AppSettings? settings,
  ) async {
    if (!hasNotificationPermission) return;
    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final when = DateTime.fromMillisecondsSinceEpoch(
        r['timestampMs'] as int,
      );
      await _postAt(
        id: r['id'] as int,
        title: '${r['name']} in a few minutes',
        body: 'Adhan follows shortly.',
        at: when,
        type: NotificationType.preAlert,
        muted: false,
        settings: settings,
        payload: r['name'] as String?,
      );
    }
  }

  /// Cross-platform posting core. Android: exact `zonedSchedule`. Linux:
  /// temporary timer that posts via `show` (the shared scheduling math is
  /// identical, so the pipeline is verifiable on desktop).
  Future<void> _postAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required NotificationType type,
    required bool muted,
    AppSettings? settings,
    String? payload,
  }) async {
    final details = _detailsFor(type, settings: settings, muted: muted);

    if (_isAndroid) {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: _exactAlarmGranted
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      return;
    }

    final delay = at.difference(DateTime.now());
    if (delay.isNegative) return;
    _timers.remove(id)?.cancel();
    _timers[id] = Timer(delay, () async {
      try {
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
          payload: payload,
        );
      } catch (_) {
        // Desk notification daemon unavailable — nothing to recover here.
      }
      _timers.remove(id);
    });
  }

  /// Builds platform-specific details for [type], keeping the two alert kinds
  /// on separate sound channels on Android and distinct sounds on Linux.
  NotificationDetails _detailsFor(
    NotificationType type, {
    AppSettings? settings,
    required bool muted,
  }) {
    if (_isLinux) {
      LinuxNotificationSound? sound;
      if (type == NotificationType.preAlert) {
        if (muted) {
          sound = null;
        } else if (settings != null) {
          final tone = ToneCatalog.byName(settings.preAlertTone);
          if (!tone.silent) {
            sound = AssetsLinuxSound('audio/${tone.assetPath}');
          } else {
            sound = ThemeLinuxSound('message');
          }
        } else {
          sound = ThemeLinuxSound('message');
        }
      } else if (settings != null && !settings.usesDeviceTone) {
        final tone = ToneCatalog.byName(settings.adhanTone);
        if (!muted && !tone.silent) {
          sound = AssetsLinuxSound('audio/${tone.assetPath}');
        }
      }
      return NotificationDetails(
        linux: LinuxNotificationDetails(
          sound: sound,
          suppressSound: muted,
          defaultActionName: 'Open',
          urgency: type == NotificationType.adhan
              ? LinuxNotificationUrgency.critical
              : LinuxNotificationUrgency.normal,
        ),
      );
    }

    if (_isAndroid) {
      final channel = switch (type) {
        NotificationType.preAlert =>
          _preAlertChannel(settings ?? const AppSettings()),
        NotificationType.adhan => muted
            ? silentAdhanChannel
            : _adhanChannel(settings ?? const AppSettings()),
      };
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: type == NotificationType.adhan
              ? Priority.max
              : Priority.high,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: channel.playSound,
          sound: channel.sound,
          audioAttributesUsage: channel.audioAttributesUsage,
        ),
      );
    }

    return const NotificationDetails();
  }

  /// Adhan channel for the currently selected tone. Ids use the
  /// `prayer_adhan_v2` prefix (bumped so Android recreates the channel instead
  /// of silently keeping the old single-sound config).
  AndroidNotificationChannel _adhanChannel(AppSettings settings) {
    const name = 'Prayer call (adhan)';
    const description = 'Plays the selected adhan at prayer entry';

    if (settings.usesDeviceTone) {
      final device = DeviceTone(
        name: settings.adhanDeviceToneName ?? 'Device sound',
        uri: settings.adhanDeviceToneUri!,
      );
      return AndroidNotificationChannel(
        'prayer_adhan_v2_${device.slug}',
        name,
        description: description,
        importance: Importance.max,
        playSound: true,
        sound: UriAndroidNotificationSound(device.uri),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }

    final tone = ToneCatalog.byName(settings.adhanTone);
    if (tone.silent) {
      return const AndroidNotificationChannel(
        'prayer_adhan_v2_silent',
        name,
        description: description,
        importance: Importance.max,
        playSound: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }

    if (tone.androidRawResource.isEmpty) {
      return adhanChannel;
    }

    return AndroidNotificationChannel(
      'prayer_adhan_v2_${tone.androidRawResource}',
      name,
      description: description,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(tone.androidRawResource),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Pre-prayer alert channel for the selected sound. Like the adhan it gets
  /// its own per-tone id (`pre_prayer_alert_v2_*`) so Android recreates the
  /// channel with the new sound instead of keeping the stale one.
  AndroidNotificationChannel _preAlertChannel(AppSettings settings) {
    final tone = ToneCatalog.byName(settings.preAlertTone);
    if (tone.silent) {
      return const AndroidNotificationChannel(
        'pre_prayer_alert_v2_silent',
        'Pre-prayer alert (muted)',
        description: 'Countdown card without an audible alert',
        importance: Importance.high,
        playSound: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }
    if (tone.androidRawResource.isEmpty) {
      return preAlertChannel;
    }
    return AndroidNotificationChannel(
      'pre_prayer_alert_v2_${tone.androidRawResource}',
      preAlertChannel.name,
      description: preAlertChannel.description,
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(tone.androidRawResource),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Raw resource used by the native countdown-card channel for the selected
  /// pre-prayer sound. `'silent'` signals a silent channel; anything else is
  /// a res/raw name held by both the Dart and native sides.
  static String _preAlertRawResource(AppSettings settings) {
    final tone = ToneCatalog.byName(settings.preAlertTone);
    if (tone.silent) return 'silent';
    return tone.androidRawResource.isEmpty ? 'pre_alert' : tone.androidRawResource;
  }

  DateTime _nextSunrise(PrayerDay day) {
    final now = DateTime.now();
    return day.sunrise.isAfter(now)
        ? day.sunrise
        : day.sunrise.add(const Duration(days: 1));
  }

  DateTime _nextFajr(PrayerDay day) {
    final now = DateTime.now();
    final today = day.prayer(PrayerKind.fajr)?.time;
    if (today != null && today.isAfter(now)) return today;
    return day.nextDayFajr;
  }

  Future<void> cancelAll() async {
    _timers.values.toList().forEach((timer) => timer.cancel());
    _timers.clear();

    if (!_isAndroid) return;
    await _cancelFlutterDayRange();
    try {
      await _channel.invokeMethod('cancelReminders');
    } catch (_) {}
  }

  /// Cancels every pending Flutter alert for the days around today so a stale
  /// recompute can never leave a double-firing notification behind.
  Future<void> _cancelFlutterDayRange() async {
    final today = DateTime.now();
    for (var offset = -7; offset <= 7; offset++) {
      final day = today.add(Duration(days: offset));
      for (var i = 0; i < PrayerKind.five.length; i++) {
        await _plugin.cancel(id: _adhanId(day, i));
        await _plugin.cancel(id: _reminderId(day, i));
      }
    }
    await _plugin.cancel(id: _testNotificationId);
  }

  static int _idFor(DateTime date, int prayerIndex, int bucket) {
    final epochDay = date.difference(DateTime(1970)).inDays;
    return bucket + epochDay * 10 + prayerIndex;
  }

  /// [`NotificationType.adhan`] Flutter-scheduled id for one occurrence.
  static int _adhanId(DateTime date, int prayerIndex) =>
      _idFor(date, prayerIndex, _adhanBucket);

  /// Fallback Flutter reminder id for one occurrence.
  static int _reminderId(DateTime date, int prayerIndex) =>
      _idFor(date, prayerIndex, _reminderBucket);

  /// Native decorated-card id for one occurrence.
  static int _nativeCardId(DateTime date, int prayerIndex) =>
      _idFor(date, prayerIndex, _nativeCardBucket);
}