import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mawaqit/core/navigation/app_navigator.dart';
import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/l10n/ambient_l10n.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/muted_prayers_store.dart';
import 'package:mawaqit/features/home/adhan_overlay_screen.dart';

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
/// before packaging an APK. Only the *posting* differs:
///
/// - **Android adhans** are handed to the native alarm engine ([`AdhanScheduler`]
///   behind the `mawaqit/native` MethodChannel): `AlarmManager` exact alarms
///   fire a foreground service that owns the Adhan clip, and the shell is
///   launched over the lockscreen with the occurrence stashed for
///   [`_consumePendingAdhan`] — so the call rings even when this process is
///   dead and the in-app presenter ([`AdhanOverlayScreen`]) takes over the
///   display. Flutter stays the controller — prayer times, tone, mute and IDs
///   — and never "double-rings" the adhan.
/// - **Muted adhans, pre-prayer alerts and Linux** use `zonedSchedule` (exact
///   timers) / local timers that post via the plugin's `show`, still behind
///   the same scheduling math.
///
/// Android-only details (exact-alarm permission, the silent cards, the custom
/// RemoteViews pre-prayer card) stay guarded by the platform checks in this
/// file and the native side.
class NotificationService {
  /// Single shared instance: the daily task, the home controller and settings
  /// changes must all cancel the *same* timer map on Linux, or old timers
  /// would survive a reschedule and double-fire alongside new ones.
  static final NotificationService instance = NotificationService._();

  NotificationService._() {
    // The clip plays through exactly once; when it ends the alarm dismisses
    // itself — tear everything down and let any live presenter close.
    // A manual stop transitions the player to `stopped`, never to `completed`,
    // so this cannot fire from [`stopAlarm`].
    _adhanPlayer.onPlayerComplete.listen((_) {
      if (!_alarmRinging) return;
      unawaited(_onAdhanFinished());
    });
  }

  static const String _nativeChannel = 'mawaqit/native';

  /// Application id — `android.resource://` notification sound URIs must point
  /// at the app's own raw resources. Kept in sync with the Android package.
  static const String _androidApplicationId = 'com.mawaqit.mawaqit';

  /// Binds a bundled `res/raw` sound by explicit `android.resource://` URI.
  ///
  /// The plugin's `RawResourceAndroidNotificationSound` validates the resource
  /// with `Resources.getIdentifier` before scheduling and hard-fails the whole
  /// notification with `invalid_sound` when it can't match (e.g. a stale
  /// installed APK that predates the resource). The URI form skips that
  /// pre-validation: a missing resource degrades to a silent alert instead of
  /// aborting the schedule.
  static UriAndroidNotificationSound _soundForResource(String rawName) =>
      UriAndroidNotificationSound(
        'android.resource://$_androidApplicationId/raw/$rawName',
      );

  // Deterministic per-day id spaces. `epochDay * 10 + prayerIndex` keeps every
  // prayer's id unique across days without colliding between alert kinds.
  static const int _adhanBucket = 0;
  static const int _reminderBucket = 1_000_000;
  static const int _nativeCardBucket = 2_000_000;

  /// Debug-only id for the "Test notification in 3s" settings trigger.
  ///
  /// Must fit within a signed 32-bit integer — Android's [validateId] enforces
  /// this (max = 2^31-1 = 2,147,483,647). Kept well below the nativeCard bucket
  /// start (2_000_000) to avoid collisions with scheduled prayer ids.
  static const int _testNotificationId = 1_999_999;

  /// Payload for the debug adhan trigger. It deliberately uses the live-adhan
  /// `adhan:` prefix so a full-screen-intent launch (screen locked / device
  /// asleep) is recognised by [`_raiseAdhanFromLaunch`] and raises the alarm
  /// presenter over the lockscreen — a plain payload would relaunch the app
  /// straight to the home screen instead, which is why the test used to demand
  /// unlocking the phone first.
  static const String _testAdhanPayload = '${_liveAdhanPrefix}test';

  /// Display name for the adhan test, in the active language.
  ///
  /// This was a hardcoded 'Test' constant, which leaked straight into the
  /// Arabic overlay title and the "Adhan — Test" notification body. It is only
  /// ever display copy — the test is identified by [_testAdhanPayload] and the
  /// separate `isTest` flag — so localizing it is safe.
  static String get _testAdhanName => AmbientL10n.instance.testAdhanName;

  /// Id for the OTA "new release available" notification. Must stay below
  /// 2^31-1 (Android's signed-int id cap) and clear of the native card bucket.
  static const int _updateNotificationId = 3_000_000;

  /// Payload prefix for adhan alerts so a tap / full-screen launch can be told
  /// apart from pre-prayer and OTA notifications. Followed by the prayer kind.
  static const String _liveAdhanPrefix = 'adhan:';

  /// Payload prefix for pre-prayer alerts (kept for symmetry and future use).
  static const String _preAlertPrefix = 'preAlert:';

  /// Channel for "a new Mawaqit version is available" alerts, fired once per
  /// release when an update check discovers something newer than the installed
  /// build (brewline-style OTA push notification).
  /// Channel definitions are built per-access rather than declared `const` so
  /// their user-visible names follow the device locale. The *ids* stay fixed:
  /// they are the keys Android uses to keep per-channel user preferences, so
  /// only the labels move.
  static AndroidNotificationChannel get updateChannel {
    final l10n = AmbientL10n.instance;
    return AndroidNotificationChannel(
      'ota_new_release',
      l10n.channelAppUpdates,
      description: l10n.channelAppUpdatesDescription,
      importance: Importance.high,
      playSound: true,
    );
  }

  /// Pre-prayer alert channel: audible countdown card shown `leadMinutes`
  /// early. Restored "as before" (0.3.x): the pre-prayer alert rings with the
  /// selected tone instead of being a silent card by design.
  static AndroidNotificationChannel get preAlertChannel {
    final l10n = AmbientL10n.instance;
    return AndroidNotificationChannel(
      'pre_prayer_alert_v2',
      l10n.channelPrePrayer,
      description: l10n.channelPrePrayerDescription,
      importance: Importance.high,
      playSound: true,
      sound: UriAndroidNotificationSound(
        'android.resource://com.mawaqit.mawaqit/raw/pre_alert',
      ),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Channel used for a muted adhan: the notification still appears but is
  /// silent (product default: show, don't play).
  static AndroidNotificationChannel get silentAdhanChannel {
    final l10n = AmbientL10n.instance;
    return AndroidNotificationChannel(
      'prayer_adhan_silent_v2',
      l10n.channelAdhanMuted,
      description: l10n.channelAdhanMutedDescription,
      importance: Importance.low,
      playSound: false,
    );
  }

  /// Channel for the debug adhan trigger — and the silent fallback any
  /// non-muted adhan card routed through the plugin uses. Audible adhans are
  /// owned by the native alarm engine ([`AdhanScheduler`]), so this channel
  /// only ever carries a silent full-screen card.
  static AndroidNotificationChannel get adhanTestChannel {
    final l10n = AmbientL10n.instance;
    return AndroidNotificationChannel(
      'prayer_adhan_test',
      l10n.channelAdhanTest,
      description: l10n.channelAdhanTestDescription,
      importance: Importance.max,
      playSound: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Channel for the debug pre-prayer trigger. Same principle as
  /// [`adhanTestChannel`]: the pre-prayer chime is played directly by the app
  /// ([`playPreAlertNow`]) so *nothing* depends on a channel sound that Android
  /// freezes after creation. `importance: max` makes the tray card a heads-up.
  static AndroidNotificationChannel get preAlertTestChannel {
    final l10n = AmbientL10n.instance;
    return AndroidNotificationChannel(
      'pre_prayer_alert_test',
      l10n.channelPrePrayerTest,
      description: l10n.channelPrePrayerTestDescription,
      importance: Importance.max,
      playSound: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final MethodChannel _channel = const MethodChannel(_nativeChannel);
  final Map<int, Timer> _timers = {};
  final MutedPrayersStore _mutedStore = MutedPrayersStore();

  /// Single adhan player (alarm stream) used for direct, Rakiz-style playback
  /// that rings regardless of the notification-channel sound config. The audio
  /// context is applied once and reused across fires.
  final AudioPlayer _adhanPlayer = AudioPlayer();
  bool _adhanAudioContextSet = false;

  /// Single pre-prayer chime player (alarm stream) used for direct playback so
  /// the pre-prayer test rings the selected tone deterministically, instead of
  /// depending on a notification channel whose sound Android freezes at first
  /// creation.
  final AudioPlayer _preAlertPlayer = AudioPlayer();
  bool _preAlertAudioContextSet = false;

  /// True while an adhan alarm is ringing (direct playback and/or a full-screen
  /// presenter is live). The native side uses this to route volume buttons to
  /// dismissal instead of stream volume.
  bool _alarmRinging = false;

  /// Tray notification (if any) to dismiss together with a ringing alarm.
  int? _ringingNotificationId;

  /// Hard ceiling on how long a single alarm may hold the screen, the native
  /// foreground playback service and the Do Not Disturb lift.
  ///
  /// The normal teardown is the clip running out ([`_onAdhanFinished`]), but
  /// that signal never arrives when the resolved source turns out to be
  /// unplayable at fire time — a `content://` device tone whose grant was
  /// revoked, a clip the platform refuses to decode, a silent tone that reached
  /// the native engine as an audible alarm. Without this backstop such an alarm
  /// would hold the lockscreen and keep forcing DND off until the user found it
  /// by hand. A real adhan is a few minutes, so this ceiling is generous.
  static const Duration _alarmMaxDuration = Duration(minutes: 10);

  /// Armed whenever the alarm starts ringing, cancelled by every teardown.
  Timer? _alarmWatchdog;

  /// Emits when the alarm is stopped from outside the overlay — currently the
  /// device volume/side buttons routed through [`NotificationService._onNativeCall`].
  final StreamController<void> _alarmDismissController =
      StreamController<void>.broadcast();

  /// Stream surfaced to the full-screen presenter so it can close itself when
  /// the alarm is stopped externally (e.g. volume-key dismissal).
  Stream<void> get alarmDismissed => _alarmDismissController.stream;

  /// Whether an adhan alarm is currently ringing.
  bool get isAlarmRinging => _alarmRinging;

  /// The live presenter route, when one is on screen — used to replace it
  /// instead of stacking a second full-screen alarm on top.
  Route<void>? _overlayRoute;

  /// Occurrence the native Android engine asked to present before (or while)
  /// the shell boots — consumed once the navigator is up.
  ({int id, String name})? _pendingNativeAdhan;

  bool _initialized = false;

  /// Latest read of the system accesses the adhan depends on. Starts
  /// permissive so scheduling is never blocked on a failed read — the native
  /// side degrades on its own when an access is genuinely missing.
  AlarmAccess _alarmAccess = AlarmAccess.all;

  /// Upper bound for a permission round-trip. A runtime dialog that never
  /// returns (or an isolate with no activity behind it) must not stall `init()`
  /// — and with it the entire day's schedule.
  static const Duration _permissionDeadline = Duration(seconds: 20);

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  /// Current system access, as read from the platform. Only meaningful on
  /// Android; elsewhere every access is reported as granted.
  AlarmAccess get alarmAccess => _alarmAccess;

  Future<void> init({bool allowPrompt = true, Locale? locale}) async {
    if (_initialized) return;
    _initialized = true;
    // Notification channels and shade copy are built outside the widget tree, so
    // pin the locale here — the first frame may not have run yet, and
    // `init()` is also reached from the WorkManager isolate where it never will.
    // [locale] carries the resolved AppLanguage so a user who picked a language
    // different from the device's does not get device-language notifications
    // until the next rebuild; the setter narrows anything unsupported.
    AmbientL10n.locale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    await TimezoneSetup.ensureInitialized();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_mawaqit'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          adhanBackgroundNotificationResponse,
    );

    // Kotlin → Dart direction of the native channel: notifies the app when the
    // user dismisses a ringing adhan with the volume/side buttons, when native
    // playback ends on its own, and when the engine has an occurrence ready to
    // present.
    _channel.setMethodCallHandler(_onNativeCall);

    if (_isAndroid) {
      // The shell may have been launched by a ringing adhan (full-screen
      // intent / card tap): the native side stashed the occurrence — raise
      // the presenter over it as soon as the navigator exists.
      unawaited(_consumePendingAdhan());
    }

    if (_isAndroid) {
      // Read the real system state *first*: it shows no UI, so it is safe from
      // the WorkManager isolate, and it is the only trustworthy answer to
      // "may we schedule exact alarms?" — the plugin's request call blocks on a
      // settings round-trip that may never come back, which used to leave the
      // exact-alarm flag stuck at false and silently downgrade every schedule.
      await refreshAlarmAccess();

      // POST_NOTIFICATIONS (13+) is the one access that is a plain runtime
      // dialog; everything else is granted on a system screen the user opens
      // from Settings. Skipped when [allowPrompt] is false (background isolate)
      // and when the access is already there.
      if (allowPrompt && !_alarmAccess.notifications) {
        final android = _android;
        final granted =
            await _withinDeadline(
              android?.requestNotificationsPermission() ??
                  Future<bool?>.value(null),
              'POST_NOTIFICATIONS',
            ) ??
            false;
        if (granted) {
          _alarmAccess = _alarmAccess.copyWith(notifications: true);
        } else {
          debugPrint(
            'Notifications are denied — the adhan and the pre-prayer card will '
            'not be shown. Settings → Alarm reliability can restore them.',
          );
        }
      }
    }

    // A scheduled adhan that fired while the app was closed is opened via the
    // full-screen intent — raise the presenter over the freshly-launched shell.
    await _awaitLaunchAdhan();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Awaits a permission round-trip under a deadline, swallowing the failures
  /// that a background isolate or an abandoned dialog produces. Returns null
  /// when no answer arrived, so callers can distinguish "no" from "unknown".
  static Future<T?> _withinDeadline<T>(Future<T?> request, String label) async {
    try {
      return await request.timeout(_permissionDeadline);
    } catch (e) {
      debugPrint('$label did not complete: $e');
      return null;
    }
  }

  /// Re-reads every system access behind the adhan from the platform.
  ///
  /// Purely a read — never opens a screen — so it is safe to call on resume,
  /// after the user returns from a system settings page, and from the
  /// background isolate.
  Future<AlarmAccess> refreshAlarmAccess() async {
    if (!_isAndroid) return _alarmAccess;
    try {
      final status = await _channel.invokeMapMethod<Object?, Object?>(
        'alarmAccessStatus',
      );
      _alarmAccess = AlarmAccess.fromMap(status);
    } on MissingPluginException {
      // Dev host without the native side — keep the permissive default.
    } catch (e) {
      debugPrint('Alarm access read failed: $e');
    }
    return _alarmAccess;
  }

  /// Opens the system screen that grants [permission] (exact alarms,
  /// full-screen notifications, Do Not Disturb access, battery, notifications).
  /// Returns false when the release has no such screen or nothing can handle
  /// it — the caller then just re-reads the state instead of nagging.
  Future<bool> requestAlarmAccess(AlarmPermission permission) async {
    if (!_isAndroid) return true;

    if (permission == AlarmPermission.notifications) {
      // A runtime dialog is friendlier than a settings screen for a first launch
      // on 13+; a hard denial can only be undone in Settings, so fall through to
      // the app's notification page when the dialog does not settle it.
      final granted =
          await _withinDeadline(
            _android?.requestNotificationsPermission() ??
                Future<bool?>.value(null),
            'POST_NOTIFICATIONS',
          ) ??
          false;
      if (granted) {
        _alarmAccess = _alarmAccess.copyWith(notifications: true);
        return true;
      }
    }

    var opened = false;
    try {
      opened =
          await _channel.invokeMethod<bool>('requestAlarmAccess', {
            'key': permission.key,
          }) ??
          false;
    } catch (e) {
      debugPrint('Could not open ${permission.name} settings: $e');
    }
    return opened;
  }

  /// Re-asks POST_NOTIFICATIONS and re-reads every other access — surfaced from
  /// Settings so a first-launch denial can be undone without reinstalling.
  ///
  /// Only the runtime dialog is re-asked here: the special-access states
  /// (exact alarms, full-screen, DND, battery) are each granted on their own
  /// system screen, which the "Alarm reliability" rows open on demand. A
  /// dialog cannot move them, and asking for one would report a stale answer.
  Future<bool> ensurePermissions() async {
    if (!_isAndroid) return true;
    if (!_alarmAccess.notifications) {
      final granted =
          await _withinDeadline(
            _android?.requestNotificationsPermission() ??
                Future<bool?>.value(null),
            'POST_NOTIFICATIONS',
          ) ??
          false;
      if (granted) {
        _alarmAccess = _alarmAccess.copyWith(notifications: true);
      }
    }
    await refreshAlarmAccess();
    if (!_alarmAccess.fullScreenIntent) {
      debugPrint(
        'Full-screen intent access was denied — the lockscreen adhan alarm '
        'falls back to a heads-up card until it is granted in Settings.',
      );
    }
    if (!_alarmAccess.overlay) {
      debugPrint(
        'Display over other apps was denied — while the phone is unlocked and '
        'in use, the adhan can only appear as a heads-up card, until it is '
        'granted in Settings.',
      );
    }
    return hasNotificationPermission;
  }

  /// Whether `AlarmManager` currently allows exact alarms (Android only, and
  /// `false` only when the platform says so — never guessed).
  bool get canUseExactAlarms => !_isAndroid || _alarmAccess.exactAlarms;
  bool get hasNotificationPermission =>
      !_isAndroid || _alarmAccess.notifications;

  /// Android 14+: whether notification full-screen intents may launch the alarm
  /// presenter over the lockscreen. False on older Androids only if the user
  /// explicitly revokes the access.
  bool get canUseFullScreenIntents =>
      !_isAndroid || _alarmAccess.fullScreenIntent;

  /// Whether the adhan may take the screen of an app the user is already in
  /// ("Display over other apps"). Without it Android downgrades the alarm to a
  /// heads-up card whenever the phone is unlocked — see
  /// `AdhanScheduler.forceShowAdhan`.
  bool get canShowOverOtherApps => !_isAndroid || _alarmAccess.overlay;

  /// (Re)schedules all notifications for [day]. Always cancels what was left
  /// over from a previous run first so stale entries can never double-fire.
  Future<void> scheduleDay(PrayerDay day, AppSettings settings) async {
    await cancelAll();

    await _scheduleAdhanAlarms(day, settings);
    if (settings.leadMinutes <= 0 || !settings.prePrayerEnabled) return;

    // On Android the native engine owns the pre-prayer cards, and it takes care
    // of degrading to an inexact alarm when the exact-alarm access is missing.
    // The Dart side therefore does NOT gate this on the permission state: a
    // stale "false" (a dialog that never returned, or a reschedule from the
    // background isolate) used to skip the native cards entirely and fall back
    // to a plugin timer the system is free to drop — which is exactly how the
    // pre-prayer reminder went missing on strict devices.
    if (_isAndroid) {
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

  /// Debug trigger (settings): fires a real notification for [kind] 3 seconds
  /// out, using the currently selected tone and respecting that kind's kill
  /// switch.
  ///
  /// **Adhan** — behaves exactly like the real prayer-entry alarm:
  /// - on Android it is handed to the native exact-alarm engine *immediately*
  ///   (AlarmManager → foreground-service audio + the shell raised over the
  ///   lockscreen for the in-app presenter), so it
  ///   rings and takes over the lockscreen even when the app is frozen or
  ///   killed within the 3-second window — a Dart `Timer` cannot be trusted to
  ///   fire on a backgrounded phone, which made the old test feel dead right
  ///   when it mattered (tap, lock, expect an alarm);
  /// - on desktop the selected tone plays **directly** through audioplayers on
  ///   the alarm stream (one pass; the presenter closes when the clip ends) and
  ///   the full-screen presenter is pushed over the app;
  /// - dismissible via the volume/side buttons (native → `alarmDismissRequest`)
  ///   or the on-screen Stop control.
  ///
  /// **Pre-Prayer** — plays the selected pre-prayer chime directly (alarm
  /// stream) and posts the countdown card silently on its own channel; no
  /// full-screen takeover. Runs on a short Dart timer because nothing about it
  /// needs to survive a backgrounded process.
  ///
  /// Notifications, exact-alarm and Android 14+ full-screen access are re-asked
  /// first, because a first-launch denial would otherwise leave the test dead.
  /// Returns false when notification access is missing so the caller can say so
  /// instead of pretending the test was armed.
  Future<bool> scheduleTestNotification({
    NotificationKind kind = NotificationKind.adhan,
    AppSettings? settings,
  }) async {
    final currentSettings = settings ?? const AppSettings();
    if (_isAndroid) {
      final granted = await ensurePermissions();
      if (!granted) {
        return false;
      }
    }

    // Android adhans (audible AND silent) are handed to the native exact-alarm
    // engine right now. The broadcast receiver fires with exact-alarm
    // privileges and is exempt from background-start restrictions, so the
    // full-screen alarm + audio happen even if the app is backgrounded — or
    // killed — before the 3-second window elapses.
    if (_isAndroid && kind == NotificationKind.adhan) {
      await _scheduleNativeTestAdhan(currentSettings);
      return true;
    }

    Future<void> onTimer() async {
      try {
        switch (kind) {
          case NotificationKind.prePrayer:
            await _firePrePrayerTest(currentSettings);
          case NotificationKind.adhan:
            await _fireAdhanTest(currentSettings);
        }
      } catch (e, st) {
        debugPrint('Test notification post failed: $e\n$st');
      }
      _timers.remove(_testNotificationId);
    }

    try {
      _timers.remove(_testNotificationId)?.cancel();
      _timers[_testNotificationId] = Timer(const Duration(seconds: 3), onTimer);
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
      _timers.remove(_testNotificationId);
      rethrow;
    }
    return true;
  }

  Future<void> _firePrePrayerTest(AppSettings settings) async {
    if (!settings.prePrayerEnabled) return;
    final tone = ToneCatalog.byName(settings.preAlertTone);
    final audible = !tone.silent && tone.assetPath.isNotEmpty;

    final details = _isAndroid
        ? _preAlertTestDetails()
        : _detailsFor(
            NotificationType.preAlert,
            settings: settings,
            muted: true,
          );

    // Play the chime directly (alarm stream) so it rings no matter what a
    // notification channel's frozen sound config says; the tray card is then
    // deliberately silent (playSound: false) to avoid a double ring. A silent
    // tone just posts the card, matching the "muted" preference.
    if (audible) await playPreAlertNow(settings);
    await _plugin.show(
      id: _testNotificationId,
      title: AmbientL10n.instance.testPrePrayerTitle,
      body: audible
          ? AmbientL10n.instance.testPrePrayerBodyAudible(
              settings.leadMinutes,
              tone.name,
            )
          : AmbientL10n.instance.testPrePrayerBodySilent,
      notificationDetails: details,
      payload: '${_preAlertPrefix}test',
    );
  }

  Future<void> _fireAdhanTest(AppSettings settings) async {
    // A disabled adhan sound — and a selected "Silent" tone — still test the
    // full-screen card silently. Both resolve to the same muted treatment, so
    // neither can leave a presenter up with nothing playing behind it.
    final muted = !adhanIsAudible(settings);
    final tone = ToneCatalog.byName(settings.adhanTone);
    final l10n = AmbientL10n.instance;
    final title = l10n.testAdhanTitle;
    final body = !settings.adhanSoundEnabled
        ? l10n.testAdhanBodySoundOff
        : tone.silent
        ? l10n.testAdhanBodySilentTone
        : l10n.testAdhanBodyAudible(tone.name);

    // Android tests are armed natively at tap time (see
    // `scheduleTestNotification`) and never reach this timer path — this is
    // the desktop stand-in.
    if (muted) {
      await _plugin.show(
        id: _testNotificationId,
        title: title,
        body: body,
        notificationDetails: _detailsFor(
          NotificationType.adhan,
          settings: settings,
          muted: true,
        ),
        payload: _testAdhanPayload,
      );
      return;
    }
    if (!await playAdhanNow(settings)) {
      // The source was playable-looking but the engine refused it. Show the
      // quiet card instead of an alarm that owns the screen and sounds nothing.
      await _plugin.show(
        id: _testNotificationId,
        title: title,
        body: AmbientL10n.instance.soundUnplayableBody,
        notificationDetails: _detailsFor(
          NotificationType.adhan,
          settings: settings,
          muted: true,
        ),
        payload: _testAdhanPayload,
      );
      return;
    }
    showAdhanOverlay(
      title: _testAdhanName,
      notificationId: _testNotificationId,
    );
    await _plugin.show(
      id: _testNotificationId,
      title: title,
      body: body,
      notificationDetails: _detailsFor(
        NotificationType.adhan,
        settings: settings,
        muted: true,
      ),
      payload: _testAdhanPayload,
    );
  }

  /// Fires the live adhan the moment its prayer time is reached while the app
  /// is open. On Android the native alarm engine owns the call: the scheduled
  /// occurrence is cancelled first (so AlarmManager doesn't also fire it — the
  /// "two Adhan" bug) then handed off to the native foreground service, which
  /// rings even when the phone is locked and raises this app's own presenter
  /// over the lockscreen. On desktop
  /// the tone is played **directly** (audioplayers, alarm stream) and the
  /// full-screen presenter is pushed so the whole pipeline stays verifiable
  /// without an Android device.
  Future<void> firePrayerAdhan({
    required PrayerDay day,
    required PrayerTime prayer,
    required AppSettings settings,
  }) async {
    final index = day.prayers.indexWhere((p) => p.kind == prayer.kind);
    if (index < 0) return;
    final id = _adhanId(day.date, index);

    final l10n = AmbientL10n.instance;
    final prayerName = prayer.kind.localized(l10n);
    final title = l10n.notifAdhanTitle(prayerName);
    final payload = '$_liveAdhanPrefix${prayer.kind.name}';
    final body = l10n.notifPrayerAtTime(
      prayerName,
      TimeFormatter.clock(prayer.time),
    );
    final occurrenceMuted = (await _mutedStore.load()).contains(
      prayerIdFor(day.date, prayer.kind),
    );

    // A muted occurrence, and every occurrence with nothing playable to ring
    // (the "Silent" tone, or a device tone that no longer resolves), posts a
    // quiet card and stops there. The previous guard only checked the
    // adhan-sound switch, so a Silent tone fell through to the audible path:
    // playback started nothing, the presenter went up, and nothing was ever
    // going to dismiss either of them.
    final audible = adhanIsAudible(settings);
    if (occurrenceMuted || !audible) {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _detailsFor(
          NotificationType.adhan,
          settings: settings,
          muted: true,
        ),
        payload: payload,
      );
      return;
    }

    if (_isAndroid) {
      try {
        await _channel.invokeMethod('cancelAdhan', {'id': id});
      } catch (_) {}
      await _fireNativeAdhanNow(
        id,
        prayerName,
        settings,
        prayerTime: prayer.time,
      );
      return;
    }

    try {
      await _plugin.cancel(id: id);
    } catch (_) {}

    if (!await playAdhanNow(settings)) {
      await _plugin.show(
        id: id,
        title: title,
        body: AmbientL10n.instance.soundUnplayableBody,
        notificationDetails: _detailsFor(
          NotificationType.adhan,
          settings: settings,
          muted: true,
        ),
        payload: payload,
      );
      return;
    }
    showAdhanOverlay(title: prayerName, notificationId: id);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _detailsFor(
        NotificationType.adhan,
        settings: settings,
        muted: true,
      ),
      payload: payload,
    );
  }

  /// Fires the live pre-prayer reminder the moment its lead-time boundary is
  /// crossed while the app is open — mirroring [`firePrayerAdhan`]: the chime
  /// plays **directly** (alarm stream) and the scheduled occurrence for that
  /// prayer (native AlarmManager card or the plain-flutter fallback) is
  /// cancelled first, so the real reminder rings the selected tone
  /// deterministically instead of depending on a channel sound Android may have
  /// frozen. When the app is closed there is no Dart engine, so the scheduled
  /// per-tone channel sound still covers that case on its own.
  Future<void> firePrayerReminder({
    required PrayerDay day,
    required PrayerTime prayer,
    required AppSettings settings,
  }) async {
    if (!settings.prePrayerEnabled || settings.leadMinutes <= 0) return;
    final index = day.prayers.indexWhere((p) => p.kind == prayer.kind);
    if (index < 0) return;

    // Cancel the scheduled occurrence before ringing, in whichever id space
    // that occurrence was scheduled into (see [_buildReminders]): the native
    // AlarmManager card on Android, the plugin's `zonedSchedule` entry
    // everywhere else. Cancelling an id that was never posted is a no-op, so
    // both are safe to issue unconditionally.
    final nativeId = _nativeCardId(day.date, index);
    try {
      if (_isAndroid) {
        await _channel.invokeMethod('cancelReminder', {'id': nativeId});
      }
    } catch (_) {}
    final reminderId = _reminderId(day.date, index);
    try {
      await _plugin.cancel(id: reminderId);
    } catch (_) {}

    final tone = ToneCatalog.byName(settings.preAlertTone);
    final audible = !tone.silent && tone.assetPath.isNotEmpty;
    if (audible) await playPreAlertNow(settings);

    // Silent tray card on the same channel the debug trigger uses — the chime
    // already rang directly, a second channel sound would echo on top.
    final l10n = AmbientL10n.instance;
    final prayerName = prayer.kind.localized(l10n);
    await _plugin.show(
      id: reminderId,
      title: settings.leadMinutes == 1
          ? l10n.notifReminderInOneMinute(prayerName)
          : l10n.notifReminderInMinutes(prayerName, settings.leadMinutes),
      body: l10n.notifReminderBodyWithTone(
        TimeFormatter.clock(prayer.time),
        audible ? tone.name : l10n.chimeMuted,
      ),
      notificationDetails: _isAndroid
          ? _preAlertTestDetails()
          : _detailsFor(
              NotificationType.preAlert,
              settings: settings,
              muted: true,
            ),
      // Opaque identifier; nothing parses it (only `adhan:`-prefixed payloads
      // are acted on). Using the enum name rather than the display label keeps it
      // locale-independent.
      payload: prayer.kind.name,
    );
  }

  /// Plays the selected adhan tone **directly** through audioplayers on the
  /// alarm stream — exactly one pass, never looping. When the clip ends the
  /// alarm dismisses itself (see the `_adhanPlayer.onPlayerComplete` listener),
  /// so the call and its presenter close together. On desktop this is what
  /// makes the call actually ring while the app is open — the scheduled path
  /// relies on the notification sound, which cannot be frozen the way an
  /// Android channel sound can. On Android the native alarm engine owns audio,
  /// so this only runs as the desktop stand-in (a muted adhan never starts —
  /// `adhanSoundEnabled` guard).
  ///
  /// Returns whether playback actually started. Callers must not raise the
  /// full-screen presenter on a `false`: the source can be accepted by the
  /// setting yet rejected by the platform — a device sound whose file has been
  /// moved or whose URI grant was revoked, or a codec the engine won't decode —
  /// and a presenter over silence is the same orphan alarm as a silent tone
  /// reaching the native engine.
  Future<bool> playAdhanNow(AppSettings settings, {int? notificationId}) async {
    if (!settings.adhanSoundEnabled) return false;
    final source = _adhanSource(settings);
    if (source == null) return false;
    try {
      if (!_adhanAudioContextSet) {
        // Alarm usage: rings on the alarm stream and takes transient audio
        // focus (music ducks out of the way, alarm ends → music resumes).
        await _adhanPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              usageType: AndroidUsageType.alarm,
              contentType: AndroidContentType.music,
              audioFocus: AndroidAudioFocus.gainTransient,
            ),
          ),
        );
        _adhanAudioContextSet = true;
      }
      await _adhanPlayer.stop();
      // One pass only: the completion listener dismisses the alarm when the
      // clip runs out instead of restarting it forever.
      await _adhanPlayer.setReleaseMode(ReleaseMode.release);
      await _adhanPlayer.play(source);
      _alarmRinging = true;
      _armAlarmWatchdog();
      _ringingNotificationId = notificationId ?? _ringingNotificationId;
      await _setAlarmActive(true);
      return true;
    } catch (e) {
      debugPrint('Adhan playback failed: $e');
      return false;
    }
  }

  /// Stops any running adhan playback.
  Future<void> stopAdhanPlayback() async {
    try {
      await _adhanPlayer.stop();
    } catch (_) {}
  }

  /// Plays the selected pre-prayer chime **directly** through audioplayers on
  /// the alarm stream — a single, non-looping chime — so the pre-prayer test
  /// rings the chosen tone deterministically. This mirrors [`playAdhanNow`]:
  /// channel sounds are frozen at first creation on Android and easily silenced,
  /// direct playback cannot be. A muted tone is a no-op (nothing audible).
  Future<void> playPreAlertNow(AppSettings settings) async {
    final tone = ToneCatalog.byName(settings.preAlertTone);
    if (tone.silent || tone.assetPath.isEmpty) return;
    try {
      if (!_preAlertAudioContextSet) {
        await _preAlertPlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              usageType: AndroidUsageType.alarm,
              contentType: AndroidContentType.sonification,
              audioFocus: AndroidAudioFocus.gainTransient,
            ),
          ),
        );
        _preAlertAudioContextSet = true;
      }
      await _preAlertPlayer.stop();
      await _preAlertPlayer.setReleaseMode(ReleaseMode.release);
      await _preAlertPlayer.play(AssetSource(tone.assetPath));
    } catch (e) {
      debugPrint('Pre-prayer playback failed: $e');
    }
  }

  /// Starts the ceiling on how long this alarm may live. Re-arms on every
  /// occurrence, so a second adhan gets a full window rather than inheriting
  /// the previous one's remaining time.
  void _armAlarmWatchdog() {
    _alarmWatchdog?.cancel();
    _alarmWatchdog = Timer(_alarmMaxDuration, () {
      debugPrint(
        'Adhan exceeded the maximum alarm duration — stopping it so it cannot '
        'hold the screen and the Do Not Disturb lift indefinitely.',
      );
      unawaited(_onAdhanFinished());
    });
  }

  void _disarmAlarmWatchdog() {
    _alarmWatchdog?.cancel();
    _alarmWatchdog = null;
  }

  /// Stops the ringing adhan and, when given, dismisses the mirroring tray
  /// notification. Used by the full-screen presenter's Stop control, by the
  /// native volume-button dismissal path and by the end-of-clip teardown.
  Future<void> stopAlarm({int? notificationId}) async {
    // Clear the ringing flag first: any echo the stop provokes (player
    // completion, the native stop broadcast) is ignored instead of re-entering.
    final wasRinging = _alarmRinging;
    _alarmRinging = false;
    _disarmAlarmWatchdog();
    await stopAdhanPlayback();
    if (_isAndroid) {
      // Tear down any native alarm (foreground service + shell takeover)
      // when the caller stops it from the app — e.g. a reschedule while the
      // call is ringing. Swing both directions so audio ownership is single.
      try {
        await _channel.invokeMethod('stopAdhan');
      } catch (_) {}
    }
    if (notificationId != null) {
      try {
        await _plugin.cancel(id: notificationId);
      } catch (_) {}
    }
    _ringingNotificationId = null;
    if (wasRinging) {
      await _setAlarmActive(false);
    }
  }

  /// The clip ran out: stop the alarm and tell the presenter to close itself,
  /// so a finished call never restarts or lingers on screen.
  Future<void> _onAdhanFinished() async {
    final id = _ringingNotificationId;
    await stopAlarm(notificationId: id);
    if (!_alarmDismissController.isClosed) {
      _alarmDismissController.add(null);
    }
  }

  /// Raises the full-screen adhan presenter over the app when it is open and
  /// arms the volume-button dismissal for the given tray notification. No-op
  /// when the navigator is unavailable (e.g. app backgrounded). A presenter
  /// that is already up is replaced in place — a re-fired test or a new
  /// occurrence must never stack a second alarm screen on top.
  void showAdhanOverlay({required String title, int? notificationId}) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    if (notificationId != null) {
      _ringingNotificationId = notificationId;
      unawaited(_setAlarmActive(true));
      _alarmRinging = true;
      _armAlarmWatchdog();
    }
    final previous = _overlayRoute;
    if (previous != null) {
      _overlayRoute = null;
      try {
        navigator.removeRoute(previous);
      } catch (_) {
        // Already popped — nothing to replace.
      }
    }
    final route = PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) =>
          AdhanOverlayScreen(title: title, notificationId: notificationId),
    );
    _overlayRoute = route;
    navigator.push(route).whenComplete(() {
      if (_overlayRoute == route) {
        _overlayRoute = null;
      }
    });
  }

  /// Handles a tapped / opened notification (foreground or via the full-screen
  /// intent when the app is already around). Adhan responses raise the
  /// presenter; the pre-prayer and OTA payloads need no takeover.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith(_liveAdhanPrefix)) {
      _raiseAdhanFromLaunch(payload, notificationId: response.id);
    }
  }

  /// Native → Dart calls on `mawaqit/native`.
  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'alarmDismissRequest':
        await _dismissFromVolume();
      case 'alarmStopped':
        // The native engine stopped on its own (clip finished, tray Stop
        // action) — close the presenter instead of leaving it up in silence.
        await _onNativeAlarmStopped(call.arguments);
      case 'adhanFired':
        // The engine has an occurrence ready to present (shell already up).
        unawaited(_consumePendingAdhan());
    }
    return null;
  }

  /// A stop that originated on the native side. Ignored when nothing is
  /// ringing on this side anymore (echo of a Dart-initiated stop) or when it
  /// belongs to an occurrence other than the one currently presented.
  Future<void> _onNativeAlarmStopped(Object? arguments) async {
    if (!_alarmRinging) return;
    int? stoppedId;
    if (arguments is Map) {
      stoppedId = (arguments['id'] as num?)?.toInt();
    }
    final ringingId = _ringingNotificationId;
    if (stoppedId != null &&
        stoppedId != -1 &&
        ringingId != null &&
        stoppedId != ringingId) {
      return;
    }
    await stopAlarm(notificationId: ringingId);
    if (!_alarmDismissController.isClosed) {
      _alarmDismissController.add(null);
    }
  }

  /// Pulls the occurrence the native Android engine stashed for the presenter
  /// (set right before the shell is launched over the lockscreen) and raises
  /// it once the navigator exists. Called from [`init`] (cold start) and on
  /// every `adhanFired` ping (shell already alive). Retries briefly when the
  /// native handler isn't wired yet — the engine can still be coming up while
  /// `init()` runs, and an alarm must never be dropped to that race.
  Future<void> _consumePendingAdhan({int attempt = 0}) async {
    try {
      final data = await _channel.invokeMapMethod<dynamic, dynamic>(
        'consumePendingAdhan',
      );
      if (data == null) return;
      final name = data['name'] as String? ?? 'Prayer';
      final id = (data['id'] as num?)?.toInt() ?? -1;
      if (id == -1) return;
      _pendingNativeAdhan = (id: id, name: name);
      _raisePendingNativeAdhan();
    } catch (_) {
      if (attempt < 10) {
        await Future.delayed(const Duration(milliseconds: 250));
        await _consumePendingAdhan(attempt: attempt + 1);
      }
    }
  }

  /// Presents the stashed native occurrence, retrying briefly while the
  /// engine is still booting: the alarm must not be dropped just because the
  /// navigator wasn't mounted on the first attempt.
  void _raisePendingNativeAdhan() {
    var attempts = 0;
    void attempt() {
      final pending = _pendingNativeAdhan;
      if (pending == null) return;
      if (appNavigatorKey.currentState == null) {
        if (attempts++ < 40) {
          Future.delayed(const Duration(milliseconds: 250), attempt);
        }
        return;
      }
      _pendingNativeAdhan = null;
      showAdhanOverlay(title: pending.name, notificationId: pending.id);
    }

    attempt();
  }

  /// Volume/side-button dismissal: stop playback, clear the tray notification
  /// and tell any live presenter to close.
  Future<void> _dismissFromVolume() async {
    await stopAlarm(notificationId: _ringingNotificationId);
    if (!_alarmDismissController.isClosed) {
      _alarmDismissController.add(null);
    }
  }

  /// Tells the native side whether a ringing alarm is active so it routes
  /// volume keys to dismissal. Android-only; a no-op on desktop.
  Future<void> _setAlarmActive(bool active) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('setAlarmActive', {'active': active});
    } catch (_) {}
  }

  /// If the app was opened by an adhan full-screen notification (device was
  /// asleep), wait for the navigator and raise the presenter so the ringing
  /// alarm can be dismissed on screen. Sound is not restarted here — the
  /// mirroring notification's channel sound already plays, and the presenter
  /// only owns dismissal.
  Future<void> _awaitLaunchAdhan() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final response = details!.notificationResponse;
        if (response == null) return;
        final payload = response.payload;
        if (payload != null && payload.startsWith(_liveAdhanPrefix)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _raiseAdhanFromLaunch(payload, notificationId: response.id);
          });
        }
      }
    } catch (_) {}
  }

  void _raiseAdhanFromLaunch(String payload, {int? notificationId}) {
    final prayer = payload.substring(_liveAdhanPrefix.length);
    final label = prayer.isEmpty
        ? 'Prayer'
        : prayer[0].toUpperCase() + prayer.substring(1);
    // The presenter's eyebrow already says "ADHAN" — pass the bare name.
    showAdhanOverlay(title: label, notificationId: notificationId);
  }

  /// Resolves the selected tone to an audioplayers [`Source`], or null when
  /// there is nothing audible to play (muted tone or empty device URI).
  Source? _adhanSource(AppSettings settings) {
    if (settings.usesDeviceTone &&
        (settings.adhanDeviceToneUri?.isNotEmpty ?? false)) {
      // `content://` document URIs are accepted by the Android MediaPlayer
      // through `DeviceFileSource`, exactly like the preview path.
      return DeviceFileSource(settings.adhanDeviceToneUri!);
    }
    final tone = ToneCatalog.byName(settings.adhanTone);
    if (tone.silent || tone.assetPath.isEmpty) return null;
    return AssetSource(tone.assetPath);
  }

  /// Notification details for the debug pre-prayer trigger: a heads-up card on
  /// a silent channel — the chime is played directly by [`playPreAlertNow`],
  /// so no channel sound is configured (see [`preAlertTestChannel`]).
  NotificationDetails _preAlertTestDetails() {
    final details = AndroidNotificationDetails(
      preAlertTestChannel.id,
      preAlertTestChannel.name,
      channelDescription: preAlertTestChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      playSound: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    return NotificationDetails(
      android: details,
      linux: LinuxNotificationDetails(defaultActionName: 'Open'),
    );
  }

  /// Posts a "new release available" alert (once per release — the caller
  /// guards the version). Used by the OTA updater after a check finds an
  /// update so the user learns about it even before opening the app.
  Future<void> notifyUpdateAvailable({
    required String version,
    required String releaseNotes,
  }) async {
    if (!hasNotificationPermission) return;
    await _ensurePostable();
    await _plugin.show(
      id: _updateNotificationId,
      title: AmbientL10n.instance.notifUpdateAvailable(version),
      body: _updateSummary(releaseNotes),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          updateChannel.id,
          updateChannel.name,
          channelDescription: updateChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.recommendation,
          playSound: true,
        ),
        linux: LinuxNotificationDetails(defaultActionName: 'Open'),
      ),
      payload: version,
    );
  }

  /// First meaningful line of the release notes as the notification body,
  /// falling back to a generic prompt when the notes are empty.
  static String _updateSummary(String notes) {
    for (final raw in notes.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final bullet =
          line.startsWith('-') || line.startsWith('•') || line.startsWith('*')
          ? line.substring(1).trim()
          : line;
      final plain = bullet.replaceAll('**', '').replaceAll('*', '');
      if (plain.isNotEmpty) return plain;
    }
    return 'A new version of Mawaqit is ready to install.';
  }

  /// Initializes just the plugin plumbing (no permission prompts) — needed in
  /// background isolates, where the foreground-only permission dialogs are
  /// unavailable.
  Future<void> _ensurePostable() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_mawaqit'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
    );
  }

  /// Human-readable id for one prayer occurrence, e.g. `"2026-09-21_maghrib"`.
  static String prayerIdFor(DateTime date, PrayerKind kind) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-${d}_${kind.name}';
  }

  /// Whether the adhan is genuinely audible for [settings].
  ///
  /// The single source of truth for "does this occurrence make a sound", used by
  /// the live path, the scheduled path and the native hand-off. A `Silent` tone
  /// — or a device-tone URI that no longer resolves to anything playable — must
  /// take the *muted* path end to end: a quiet card, no full-screen takeover,
  /// no native foreground playback service and no Do Not Disturb lift.
  ///
  /// This matters because the native engine treats `muted: false` as "an
  /// audible alarm": it arms `AlarmManager`, starts the playback service and
  /// forces silent mode off, then relies on playback reporting completion to
  /// tear all of that down. With no playable source that completion never
  /// arrives, so the alarm simply never dismisses itself.
  static bool adhanIsAudible(AppSettings settings) {
    if (!settings.adhanSoundEnabled) return false;
    if (settings.usesDeviceTone &&
        (settings.adhanDeviceToneUri?.isNotEmpty ?? false)) {
      return true;
    }
    final tone = ToneCatalog.byName(settings.adhanTone);
    return !tone.silent &&
        tone.androidRawResource.isNotEmpty &&
        tone.assetPath.isNotEmpty;
  }

  Future<void> _scheduleAdhanAlarms(PrayerDay day, AppSettings settings) async {
    if (!settings.adhanSoundEnabled) return;
    if (!hasNotificationPermission) return;

    final muted = await _mutedStore.load();
    final now = DateTime.now();
    final audible = adhanIsAudible(settings);

    // Today, plus tomorrow's Fajr: without it the whole Isha → Fajr window runs
    // unarmed whenever the app is not opened, and Fajr is the one prayer a user
    // is most likely to sleep through. Ids stay in tomorrow's own day bucket so
    // the next daily recompute re-arms this same occurrence rather than adding
    // a duplicate.
    final occurrences = <({PrayerTime prayer, DateTime date, int index})>[
      for (var i = 0; i < day.prayers.length; i++)
        (prayer: day.prayers[i], date: day.date, index: i),
      (
        prayer: PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr),
        date: day.date.add(const Duration(days: 1)),
        index: 0,
      ),
    ];

    for (final occurrence in occurrences) {
      final p = occurrence.prayer;
      if (!p.time.isAfter(now)) continue;

      final id = _adhanId(occurrence.date, occurrence.index);
      final prayerId = prayerIdFor(occurrence.date, p.kind);
      final isMuted = muted.contains(prayerId);

      // Audible occurrences on Android are owned by the native alarm engine
      // (AlarmManager → foreground service + shell launch), so the call
      // rings even when this process is dead and never double-plays with a
      // channel sound. Muted occurrences — and every occurrence with nothing
      // playable to ring — keep the silent Flutter card.
      if (_isAndroid && !isMuted && audible) {
        await _scheduleNativeAdhan(
          id: id,
          at: p.time,
          name: p.kind.localized(AmbientL10n.instance),
          prayerId: prayerId,
          settings: settings,
        );
        continue;
      }

      await _postAt(
        id: id,
        title: AmbientL10n.instance.notifAdhanTitle(
          p.kind.localized(AmbientL10n.instance),
        ),
        body: AmbientL10n.instance.notifPrayerAtTime(
          p.kind.localized(AmbientL10n.instance),
          TimeFormatter.clock(p.time),
        ),
        at: p.time,
        type: NotificationType.adhan,
        settings: settings,
        muted: isMuted || !audible,
        payload: '$_liveAdhanPrefix${p.kind.name}',
      );
    }
  }

  /// Hands one audible occurrence to the native alarm engine (`AlarmManager`).
  ///
  /// Flutter stays the controller (prayer times, tone, mute, IDs) and native
  /// owns the exact timing, waking, audio and lockscreen takeover.
  Future<void> _scheduleNativeAdhan({
    required int id,
    required DateTime at,
    required String name,
    required String prayerId,
    required AppSettings settings,
  }) async {
    final sound = _androidAdhanSound(settings);
    try {
      await _channel.invokeMethod('scheduleAdhan', {
        'id': id,
        'timestampMs': at.millisecondsSinceEpoch,
        'name': name,
        // Native would otherwise compose "Adhan — <name>" in English.
        'title': AmbientL10n.instance.notifAdhanTitle(name),
        'body': AmbientL10n.instance.notifPrayerAtTime(
          name,
          TimeFormatter.clock(at),
        ),
        'prayerId': prayerId,
        // Resolved here rather than trusting the caller: `muted: false` on an
        // unplayable source is what leaves the engine's foreground service,
        // full-screen intent and DND lift engaged with no completion to retire
        // them.
        'muted': !adhanIsAudible(settings),
        'soundRaw': sound.raw,
        'soundUri': sound.uri,
      });
    } catch (_) {
      // Native engine unavailable — fall back to the Flutter card so the
      // occurrence still surfaces.
      await _postAt(
        id: id,
        title: 'Adhan — $name',
        body:
            'It is now time for the $name prayer · '
            '${TimeFormatter.clock(at)}',
        at: at,
        type: NotificationType.adhan,
        settings: settings,
        muted: false,
        payload: '',
      );
    }
  }

  /// Arms the debug adhan as a real exact alarm three seconds out — audible or
  /// silent, both take over the screen like a real alarm.
  ///
  /// Every Android test goes through the native engine (never a low-importance
  /// Flutter card, which the system will not show full-screen): the receiver
  /// runs with exact-alarm privileges, exempt from the background-start
  /// restrictions that would swallow a foreground-service + activity start
  /// from a backgrounded app. The selected sound is resolved in Dart and
  /// persisted as the engine's only audio input.
  ///
  /// The alarm is ALWAYS armed natively — even without exact-alarm access,
  /// where AlarmManager degrades to `setAndAllowWhileIdle` and still fires
  /// after the app is swiped from recents. A Dart `Timer` cannot: it dies with
  /// the process, which is exactly when the test used to go silent. The timer
  /// below only covers a channel that is missing entirely (desktop/dev).
  ///
  /// A stale scheduled test is cleared first so every tap re-arms cleanly.
  Future<void> _scheduleNativeTestAdhan(AppSettings settings) async {
    try {
      await _channel.invokeMethod('cancelAdhan', {'id': _testNotificationId});
    } catch (_) {}
    final sound = _androidAdhanSound(settings);
    final args = <String, dynamic>{
      'id': _testNotificationId,
      'timestampMs': DateTime.now()
          .add(const Duration(seconds: 3))
          .millisecondsSinceEpoch,
      'name': _testAdhanName,
      'title': AmbientL10n.instance.testAdhanTitle,
      'body': AmbientL10n.instance.notifAdhanTitleName(_testAdhanName),
      'prayerId': '',
      'muted': !settings.adhanSoundEnabled,
      'isTest': true,
      'soundRaw': sound.raw,
      'soundUri': sound.uri,
    };
    try {
      await _channel.invokeMethod('scheduleAdhan', args);
    } catch (e) {
      debugPrint('Native adhan test schedule failed: $e');
      // Native engine unavailable — best-effort in-app fire. Only valid while
      // this process lives; there is no host to schedule against otherwise.
      _timers.remove(_testNotificationId)?.cancel();
      _timers[_testNotificationId] = Timer(
        const Duration(seconds: 3),
        () async {
          try {
            await _fireNativeAdhanNow(
              _testNotificationId,
              _testAdhanName,
              settings,
              isTest: true,
            );
          } catch (e, st) {
            debugPrint('Native adhan test fire failed: $e\n$st');
          }
          _timers.remove(_testNotificationId);
        },
      );
    }
  }

  /// Fires the native alarm immediately (used by the live rollover hand-off
  /// while the app is open — the foreground `fireAdhanNow` path — and as the
  /// fallback for the debug test when the native channel itself is missing).
  /// The selected sound is resolved here in Dart and passed down as the
  /// engine's only audio input.
  Future<void> _fireNativeAdhanNow(
    int id,
    String name,
    AppSettings settings, {
    bool isTest = false,
    DateTime? prayerTime,
  }) async {
    final sound = _androidAdhanSound(settings);
    try {
      await _channel.invokeMethod('fireAdhanNow', {
        'id': id,
        'name': name,
        'title': AmbientL10n.instance.notifAdhanTitle(name),
        'body': AmbientL10n.instance.notifPrayerAtTime(
          name,
          TimeFormatter.clock(prayerTime ?? DateTime.now()),
        ),
        'muted': !adhanIsAudible(settings),
        'isTest': isTest,
        'soundRaw': sound.raw,
        'soundUri': sound.uri,
      });
    } catch (e) {
      debugPrint('Native adhan fire failed: $e');
    }
  }

  /// Resolves the selected adhan to the native engine's sound descriptor: a
  /// bundled `res/raw` name or a device `content://` URI (empty = silent).
  ({String raw, String uri}) _androidAdhanSound(AppSettings settings) {
    if (settings.usesDeviceTone &&
        (settings.adhanDeviceToneUri?.isNotEmpty ?? false)) {
      return (raw: '', uri: settings.adhanDeviceToneUri!);
    }
    final tone = ToneCatalog.byName(settings.adhanTone);
    if (tone.silent || tone.androidRawResource.isEmpty) {
      return (raw: '', uri: '');
    }
    return (raw: tone.androidRawResource, uri: '');
  }

  /// Builds the reminder entries shared by the native decorated-card path and
  /// the plain-Flutter fallback.
  ///
  /// Each entry carries **two** ids, because the two delivery paths schedule
  /// into different Android id spaces: [`_nativeCardId`] for the native
  /// `AlarmManager` PendingIntent and its RemoteViews card, and
  /// [`_reminderId`] for the plugin's `zonedSchedule`. `firePrayerReminder`
  /// cancels the one matching the path it is about to deliver, and
  /// `_cancelFlutterDayRange` sweeps both — so a live chime can no longer ring
  /// on top of a scheduled card it meant to replace.
  ///
  /// Tomorrow's Fajr is included for the same reason the adhan arms it: without
  /// it the lead time before the next day's first prayer is the one reminder
  /// that only exists if the app happens to be open.
  List<Map<String, dynamic>> _buildReminders(PrayerDay day, int leadMinutes) {
    final result = <Map<String, dynamic>>[];
    final occurrences = <({PrayerTime prayer, DateTime date, int index})>[
      for (var i = 0; i < day.prayers.length; i++)
        (prayer: day.prayers[i], date: day.date, index: i),
      (
        prayer: PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr),
        date: day.date.add(const Duration(days: 1)),
        index: 0,
      ),
    ];

    for (final occurrence in occurrences) {
      final p = occurrence.prayer;
      // Offset is SUBTRACTED from the prayer time — the only place the lead is
      // applied, so rescheduling (daily task or settings change) can never
      // double-apply it.
      final at = p.time.subtract(Duration(minutes: leadMinutes));
      if (at.isAfter(DateTime.now())) {
        result.add({
          'id': _nativeCardId(occurrence.date, occurrence.index),
          'flutterId': _reminderId(occurrence.date, occurrence.index),
          'prayerId': prayerIdFor(occurrence.date, p.kind),
          'name': p.kind.localized(AmbientL10n.instance),
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
    if (settings != null && !settings.prePrayerEnabled) return;
    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final when = DateTime.fromMillisecondsSinceEpoch(r['timestampMs'] as int);
      final prayerTime = DateTime.fromMillisecondsSinceEpoch(
        r['prayerTimestampMs'] as int,
      );
      final name = r['name'] as String;
      final lead = (r['leadMinutes'] as int?) ?? settings?.leadMinutes ?? 10;
      // The plugin id space, *not* the native card id — see [_buildReminders].
      // The `flutterId` fallback keeps this resilient to a reminder map that
      // predates the split.
      final id = (r['flutterId'] as int?) ?? r['id'] as int;
      await _postAt(
        id: id,
        title: lead == 1 ? '$name in 1 minute' : '$name in $lead minutes',
        body:
            'Adhan follows at ${TimeFormatter.clock(prayerTime)} '
            '· tap to quiet.',
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
        androidScheduleMode: canUseExactAlarms
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
            sound = AssetsLinuxSound(tone.assetPath);
          } else {
            sound = ThemeLinuxSound('message');
          }
        } else {
          sound = ThemeLinuxSound('message');
        }
      } else if (settings != null && !settings.usesDeviceTone) {
        final tone = ToneCatalog.byName(settings.adhanTone);
        if (!muted && !tone.silent) {
          sound = AssetsLinuxSound(tone.assetPath);
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
        NotificationType.preAlert => _preAlertChannel(
          settings ?? const AppSettings(),
        ),
        // Audible adhans are owned by the native alarm engine, so any adhan
        // card routed through the plugin is deliberately silent on Android.
        NotificationType.adhan => muted ? silentAdhanChannel : adhanTestChannel,
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
          vibrationPattern: type == NotificationType.adhan && !muted
              ? Int64List.fromList([0, 400, 200, 400, 200, 400])
              : null,
          enableVibration: type == NotificationType.adhan && !muted,
          fullScreenIntent: type == NotificationType.adhan,
        ),
      );
    }

    return const NotificationDetails();
  }

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
    return AndroidNotificationChannel(
      'pre_prayer_alert_v2_${tone.androidRawResource}',
      preAlertChannel.name,
      description: preAlertChannel.description,
      importance: Importance.high,
      playSound: true,
      sound: _soundForResource(_preAlertRawResource(settings)),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Raw resource used by the native countdown-card channel. Uses the
  /// per-tone channel's resource when the selected tone is audible, otherwise
  /// falls back to the default `'pre_alert'`.
  static String _preAlertRawResource(AppSettings settings) {
    final tone = ToneCatalog.byName(settings.preAlertTone);
    if (tone.silent) return 'silent';
    return tone.androidRawResource.isEmpty
        ? 'pre_alert'
        : tone.androidRawResource;
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

  /// Cancels every *scheduled* alert so a recompute can re-arm the day from
  /// scratch without stale entries double-firing.
  ///
  /// Deliberately leaves a ringing adhan alone. A reschedule is triggered by
  /// entirely ordinary events — a settings change, a mute toggle, a GPS refresh,
  /// the prayer rollover itself — and none of them is a reason to cut a call off
  /// mid-way. A ringing alarm owns its own lifetime: it ends when the clip
  /// finishes, when the user stops it from the presenter, a volume key or the
  /// tray card, or at [_alarmMaxDuration].
  Future<void> cancelAll() async {
    _timers.forEach((_, timer) => timer.cancel());
    _timers.clear();

    if (!_isAndroid) return;
    await _cancelFlutterDayRange();
    // `cancelAdhans` / `cancelReminders` only drop *pending* AlarmManager
    // entries on the native side — neither touches the active alarm, so the
    // call keeps ringing through the reschedule.
    try {
      await _channel.invokeMethod('cancelAdhans');
    } catch (_) {}
    try {
      await _channel.invokeMethod('cancelReminders');
    } catch (_) {}
  }

  /// Cancels every pending Flutter alert for today and its neighbours so a
  /// stale recompute can never leave a double-firing notification behind. The
  /// ±1-day window covers every id that can exist now that tomorrow's Fajr is
  /// armed alongside today's. All cancels run concurrently — the plugin
  /// round-trip dominates and there is no ordering dependency between ids.
  ///
  /// The tray card mirroring a *ringing* adhan is spared: cancelling it would
  /// leave the call playing with no notification and no visible Stop control.
  Future<void> _cancelFlutterDayRange() async {
    final today = DateTime.now();
    final keep = _ringingNotificationId;
    final ids = <int>[
      for (var offset = -1; offset <= 1; offset++)
        for (var i = 0; i < PrayerKind.five.length; i++) ...[
          _adhanId(today.add(Duration(days: offset)), i),
          _reminderId(today.add(Duration(days: offset)), i),
        ],
      _testNotificationId,
    ];
    final doomed = ids.where((id) => id != keep).toList(growable: false);
    await Future.wait(doomed.map((id) => _plugin.cancel(id: id)));
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

/// Background-isolate handler for adhan notification responses (e.g. a
/// full-screen adhan that fired while the app was killed). A background engine
/// cannot raise Flutter UI, so this is intentionally a no-op: the full-screen
/// intent launches the foreground app, whose `init()` → `_awaitLaunchAdhan`
/// picks up the launch and raises the presenter.
@pragma('vm:entry-point')
void adhanBackgroundNotificationResponse(NotificationResponse response) {
  // Intentionally empty — the foreground engine handles the adhan takeover.
}
