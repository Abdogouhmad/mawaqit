/// Per-prayer alert choices introduced by Adhan 2.0.
///
/// One [PrayerSchedule] exists for each of the five obligatory prayers. The
/// values are *concrete*, not nullable overrides: a prayer that has never been
/// edited gets the same behaviour the app had before this model existed, so an
/// upgrade cannot silently change when or how a user's adhan rings.
///
/// Deliberately free of Flutter and localization imports: the labels shown in
/// the editor come from `AppLocalizations`, while this model only carries the
/// values the scheduler and the repository need.
library;

/// How a prayer's adhan is delivered.
///
/// [full] is the audible call with the lockscreen takeover; [silent] keeps the
/// card but drops the sound, the service and the Do Not Disturb lift. The native
/// alarm engine already understands the two cases through its existing `muted`
/// flag — this enum only decides what Dart sends it.
enum AdhanMode {
  full,
  silent;

  static AdhanMode fromName(String? name) => AdhanMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => AdhanMode.full,
  );
}

class PrayerSchedule {
  const PrayerSchedule({
    this.enabled = true,
    this.adhanOffsetMinutes = 0,
    this.reminderLeadMinutes,
    this.mode = AdhanMode.full,
  });

  /// Whether either alert for this prayer is armed. Disabling a prayer skips
  /// both its adhan and its pre-prayer card; the choice is remembered.
  final bool enabled;

  /// Minutes from the prayer time at which the adhan rings.
  ///
  /// Negative is early, positive is late, zero is at the prayer itself. Bounded
  /// to ±30 so the weekly summary stays believable and a corrupt stored value
  /// cannot arm an alarm a month away.
  final int adhanOffsetMinutes;

  /// Minutes before the prayer at which the countdown card appears.
  ///
  /// `null` means "follow the global lead time" — the behaviour before this
  /// setting existed, and the safe default for a user who never opens the
  /// editor. Zero disables the reminder for this prayer only.
  final int? reminderLeadMinutes;

  /// Audible call or quiet card.
  final AdhanMode mode;

  static const int maxOffsetMinutes = 30;
  static const int maxLeadMinutes = 30;

  /// Clamps a stored or user-entered offset into the supported range.
  static int clampOffset(int minutes) =>
      minutes.clamp(-maxOffsetMinutes, maxOffsetMinutes);

  /// Clamps a stored or user-entered lead into the supported range.
  static int clampLead(int minutes) => minutes.clamp(0, maxLeadMinutes);

  PrayerSchedule copyWith({
    bool? enabled,
    int? adhanOffsetMinutes,
    int? reminderLeadMinutes,
    bool clearReminderLead = false,
    AdhanMode? mode,
  }) {
    return PrayerSchedule(
      enabled: enabled ?? this.enabled,
      adhanOffsetMinutes: adhanOffsetMinutes ?? this.adhanOffsetMinutes,
      reminderLeadMinutes: clearReminderLead
          ? null
          : (reminderLeadMinutes ?? this.reminderLeadMinutes),
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'adhanOffsetMinutes': adhanOffsetMinutes,
    'reminderLeadMinutes': reminderLeadMinutes,
    'mode': mode.name,
  };

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    final rawOffset = json['adhanOffsetMinutes'];
    final rawLead = json['reminderLeadMinutes'];
    return PrayerSchedule(
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      adhanOffsetMinutes: rawOffset is num ? clampOffset(rawOffset.toInt()) : 0,
      reminderLeadMinutes: rawLead is num ? clampLead(rawLead.toInt()) : null,
      mode: AdhanMode.fromName(json['mode'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerSchedule &&
      other.enabled == enabled &&
      other.adhanOffsetMinutes == adhanOffsetMinutes &&
      other.reminderLeadMinutes == reminderLeadMinutes &&
      other.mode == mode;

  @override
  int get hashCode =>
      Object.hash(enabled, adhanOffsetMinutes, reminderLeadMinutes, mode);

  @override
  String toString() =>
      'PrayerSchedule(enabled: $enabled, adhanOffsetMinutes: '
      '$adhanOffsetMinutes, reminderLeadMinutes: $reminderLeadMinutes, '
      'mode: ${mode.name})';
}
