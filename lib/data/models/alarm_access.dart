import 'package:flutter/material.dart';

/// The system-level access Android requires before the adhan and the pre-prayer
/// card can be trusted to fire on time and be heard.
///
/// Each entry is granted on its own screen, on its own release, and the OS
/// revokes it silently: notifications can be off, exact alarms can fall back to
/// "batched later", the lockscreen takeover can be off, the app can be barred
/// from taking the screen of an app you are already using, and a phone in silent
/// or Do Not Disturb mode swallows the call. The model mirrors the native
/// [`AlarmAccess`](../../android/app/src/main/kotlin/com/mawaqit/mawaqit/AlarmAccess.kt)
/// status map so the settings UI can show — and fix — exactly what is missing.
///
/// [key] is the wire name shared with Kotlin and must stay in sync. The row
/// title and description are locale-dependent display copy and are deliberately
/// *not* stored here — see `AlarmPermissionL10n` in
/// lib/l10n/enum_localization.dart.
enum AlarmPermission {
  /// `POST_NOTIFICATIONS` (13+) / the per-app notifications toggle: without it
  /// no card is posted at all, however well the alarms are scheduled.
  notifications(
    key: 'notifications',
    icon: Icons.notifications_active_outlined,
  ),

  /// "Alarms & reminders" special access (12+). Without it Android batches
  /// exact alarms into the next maintenance window, so the adhan lands minutes
  /// — or hours — late.
  exactAlarms(key: 'exactAlarms', icon: Icons.alarm_on_outlined),

  /// Full-screen notifications (14+): what lets the alarm wake the display and
  /// take over the lockscreen instead of silently appearing in the shade.
  ///
  /// Locked phones only. Android deliberately refuses to launch a full-screen
  /// intent while the screen is unlocked — it downgrades the card to a
  /// heads-up notification — which is what [overlay] exists to cover.
  fullScreenIntent(key: 'fullScreenIntent', icon: Icons.fullscreen_outlined),

  /// "Display over other apps": the one access that lifts Android's
  /// background-activity-launch restriction, and therefore the only way the
  /// adhan can take the screen while the phone is unlocked and the user is in
  /// another app. Without it an in-use phone gets a heads-up card and nothing
  /// more — which is what Google Clock does too.
  ///
  /// Opt-in, and the app is complete without it: every other alarm behaviour
  /// (audio, timing, lockscreen takeover) is unaffected either way.
  overlay(key: 'overlay', icon: Icons.picture_in_picture_alt_outlined),

  /// "Do Not Disturb access": with it, a ringing adhan lifts silent mode for
  /// the length of the call (and the phone goes back to the user's own mode
  /// right after). This is the "force the adhan" switch.
  policyAccess(key: 'policyAccess', icon: Icons.do_not_disturb_on_outlined),

  /// Battery-optimisation exemption: without it the OEM's power manager can
  /// doze the app and defer the alarm — the classic "no adhan on my phone".
  battery(
    key: 'batteryUnrestricted',
    icon: Icons.battery_charging_full_outlined,
  );

  const AlarmPermission({required this.key, required this.icon});

  /// Key used by the native status map.
  final String key;

  /// Row icon in Settings.
  final IconData icon;
}

/// Immutable snapshot of [AlarmPermission] grants, read from the platform.
class AlarmAccess {
  const AlarmAccess({
    this.notifications = true,
    this.exactAlarms = true,
    this.fullScreenIntent = true,
    this.overlay = true,
    this.policyAccess = true,
    this.battery = true,
  });

  /// Everything granted — the desktop / no-Android default, where none of the
  /// system accesses exist and every alarm path is driven by the app itself.
  static const AlarmAccess all = AlarmAccess();

  final bool notifications;
  final bool exactAlarms;
  final bool fullScreenIntent;
  final bool overlay;
  final bool policyAccess;
  final bool battery;

  /// Whether [permission] is granted.
  bool granted(AlarmPermission permission) => switch (permission) {
    AlarmPermission.notifications => notifications,
    AlarmPermission.exactAlarms => exactAlarms,
    AlarmPermission.fullScreenIntent => fullScreenIntent,
    AlarmPermission.overlay => overlay,
    AlarmPermission.policyAccess => policyAccess,
    AlarmPermission.battery => battery,
  };

  /// Grants that are missing, in the order they should be fixed.
  List<AlarmPermission> get missing =>
      AlarmPermission.values.where((p) => !granted(p)).toList(growable: false);

  /// Whether the adhan can actually be trusted: the card needs notifications,
  /// the timing needs exact alarms, and the takeover needs full-screen.
  bool get canRingOnTime => notifications && exactAlarms && fullScreenIntent;

  /// Whether the adhan can reach the user whatever they are doing: audible
  /// through silent mode (Do Not Disturb access) and on top of whatever app is
  /// open ("Display over other apps").
  bool get canForceAdhan => policyAccess && overlay;

  /// Whether the adhan is guaranteed to take over the screen, on a locked
  /// phone ([fullScreenIntent]) as well as one already in use ([overlay]).
  bool get canAlwaysTakeOver => fullScreenIntent && overlay;

  AlarmAccess copyWith({
    bool? notifications,
    bool? exactAlarms,
    bool? fullScreenIntent,
    bool? overlay,
    bool? policyAccess,
    bool? battery,
  }) {
    return AlarmAccess(
      notifications: notifications ?? this.notifications,
      exactAlarms: exactAlarms ?? this.exactAlarms,
      fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
      overlay: overlay ?? this.overlay,
      policyAccess: policyAccess ?? this.policyAccess,
      battery: battery ?? this.battery,
    );
  }

  /// Parses the native `AlarmAccess.status` map. Anything the platform does not
  /// report is treated as granted: a missing key must never invent a warning
  /// the user cannot act on (e.g. a release with no such special access).
  factory AlarmAccess.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return all;
    bool read(AlarmPermission permission) {
      final value = map[permission.key];
      return value is bool ? value : true;
    }

    return AlarmAccess(
      notifications: read(AlarmPermission.notifications),
      exactAlarms: read(AlarmPermission.exactAlarms),
      fullScreenIntent: read(AlarmPermission.fullScreenIntent),
      overlay: read(AlarmPermission.overlay),
      policyAccess: read(AlarmPermission.policyAccess),
      battery: read(AlarmPermission.battery),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlarmAccess &&
      other.notifications == notifications &&
      other.exactAlarms == exactAlarms &&
      other.fullScreenIntent == fullScreenIntent &&
      other.overlay == overlay &&
      other.policyAccess == policyAccess &&
      other.battery == battery;

  @override
  int get hashCode => Object.hash(
    notifications,
    exactAlarms,
    fullScreenIntent,
    overlay,
    policyAccess,
    battery,
  );

  @override
  String toString() =>
      'AlarmAccess(notifications: $notifications, exactAlarms: $exactAlarms, '
      'fullScreenIntent: $fullScreenIntent, overlay: $overlay, '
      'policyAccess: $policyAccess, battery: $battery)';
}
