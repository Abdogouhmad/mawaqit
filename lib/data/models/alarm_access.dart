import 'package:flutter/material.dart';

/// The system-level access Android requires before the adhan and the pre-prayer
/// card can be trusted to fire on time and be heard.
///
/// Each entry is granted on its own screen, on its own release, and the OS
/// revokes it silently: notifications can be off, exact alarms can fall back to
/// "batched later", the lockscreen takeover can be off, and a phone in silent
/// or Do Not Disturb mode swallows the call. The model mirrors the native
/// [`AlarmAccess`](../../android/app/src/main/kotlin/com/mawaqit/mawaqit/AlarmAccess.kt)
/// status map so the settings UI can show — and fix — exactly what is missing.
enum AlarmPermission {
  /// `POST_NOTIFICATIONS` (13+) / the per-app notifications toggle: without it
  /// no card is posted at all, however well the alarms are scheduled.
  notifications(
    key: 'notifications',
    label: 'Notifications',
    icon: Icons.notifications_active_outlined,
    blurb: 'Show the adhan and the pre-prayer card',
  ),

  /// "Alarms & reminders" special access (12+). Without it Android batches
  /// exact alarms into the next maintenance window, so the adhan lands minutes
  /// — or hours — late.
  exactAlarms(
    key: 'exactAlarms',
    label: 'Alarms & reminders',
    icon: Icons.alarm_on_outlined,
    blurb: 'Ring exactly at prayer time instead of minutes later',
  ),

  /// Full-screen notifications (14+): what lets the alarm wake the display and
  /// take over the lockscreen instead of silently appearing in the shade.
  fullScreenIntent(
    key: 'fullScreenIntent',
    label: 'Full-screen notifications',
    icon: Icons.fullscreen_outlined,
    blurb: 'Wake the screen and take over the lockscreen',
  ),

  /// "Do Not Disturb access": with it, a ringing adhan lifts silent mode for
  /// the length of the call (and the phone goes back to the user's own mode
  /// right after). This is the "force the adhan" switch.
  policyAccess(
    key: 'policyAccess',
    label: 'Do Not Disturb access',
    icon: Icons.do_not_disturb_on_outlined,
    blurb: 'Ring the adhan even when the phone is on silent',
  ),

  /// Battery-optimisation exemption: without it the OEM's power manager can
  /// doze the app and defer the alarm — the classic "no adhan on my phone".
  battery(
    key: 'batteryUnrestricted',
    label: 'Unrestricted battery',
    icon: Icons.battery_charging_full_outlined,
    blurb: 'Stop the phone from delaying or dropping the adhan',
  );

  const AlarmPermission({
    required this.key,
    required this.label,
    required this.icon,
    required this.blurb,
  });

  /// Key used by the native status map.
  final String key;

  /// Row title in Settings.
  final String label;

  /// Row icon in Settings.
  final IconData icon;

  /// One line on what this access buys the user.
  final String blurb;
}

/// Immutable snapshot of [AlarmPermission] grants, read from the platform.
class AlarmAccess {
  const AlarmAccess({
    this.notifications = true,
    this.exactAlarms = true,
    this.fullScreenIntent = true,
    this.policyAccess = true,
    this.battery = true,
  });

  /// Everything granted — the desktop / no-Android default, where none of the
  /// system accesses exist and every alarm path is driven by the app itself.
  static const AlarmAccess all = AlarmAccess();

  final bool notifications;
  final bool exactAlarms;
  final bool fullScreenIntent;
  final bool policyAccess;
  final bool battery;

  /// Whether [permission] is granted.
  bool granted(AlarmPermission permission) => switch (permission) {
    AlarmPermission.notifications => notifications,
    AlarmPermission.exactAlarms => exactAlarms,
    AlarmPermission.fullScreenIntent => fullScreenIntent,
    AlarmPermission.policyAccess => policyAccess,
    AlarmPermission.battery => battery,
  };

  /// Grants that are missing, in the order they should be fixed.
  List<AlarmPermission> get missing =>
      AlarmPermission.values.where((p) => !granted(p)).toList(growable: false);

  /// Whether the adhan can actually be trusted: the card needs notifications,
  /// the timing needs exact alarms, and the takeover needs full-screen.
  bool get canRingOnTime => notifications && exactAlarms && fullScreenIntent;

  /// Whether the adhan can override a silenced phone.
  bool get canForceAdhan => policyAccess;

  AlarmAccess copyWith({
    bool? notifications,
    bool? exactAlarms,
    bool? fullScreenIntent,
    bool? policyAccess,
    bool? battery,
  }) {
    return AlarmAccess(
      notifications: notifications ?? this.notifications,
      exactAlarms: exactAlarms ?? this.exactAlarms,
      fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
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
      other.policyAccess == policyAccess &&
      other.battery == battery;

  @override
  int get hashCode => Object.hash(
    notifications,
    exactAlarms,
    fullScreenIntent,
    policyAccess,
    battery,
  );

  @override
  String toString() =>
      'AlarmAccess(notifications: $notifications, exactAlarms: $exactAlarms, '
      'fullScreenIntent: $fullScreenIntent, policyAccess: $policyAccess, '
      'battery: $battery)';
}
