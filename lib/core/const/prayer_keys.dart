/// Stable, non-localized identifiers for the five prayers.
///
/// Two different needs are served here and they must not be confused:
///
///  * **Persisted / wire ids** — [`PrayerKeys.id`] goes into notification ids,
///    `SharedPreferences` mute lists and the JSON handed to native. Changing one
///    orphans existing state and silently un-mutes or double-schedules prayers,
///    so these are frozen strings, *not* `PrayerKind.name`.
///  * **Display** — the Arabic and Latin names a user reads come from
///    `AppLocalizations` (see `PrayerKindL10n`), because prayer names are always
///    shown in Arabic script per feat.md §8.
library;

import 'package:mawaqit/data/models/prayer_time.dart';

abstract final class PrayerKeys {
  const PrayerKeys._();

  /// Compact machine id for [kind].
  static String id(PrayerKind kind) => switch (kind) {
    PrayerKind.fajr => 'fajr',
    PrayerKind.dhuhr => 'dhuhr',
    PrayerKind.asr => 'asr',
    PrayerKind.maghrib => 'maghrib',
    PrayerKind.isha => 'isha',
  };

  /// Reverse of [id]; `null` for anything unrecognised so a future or corrupt
  /// value is skipped rather than throwing mid-schedule.
  static PrayerKind? fromId(String id) {
    for (final kind in PrayerKind.five) {
      if (PrayerKeys.id(kind) == id) return kind;
    }
    return null;
  }

  /// Occurrence id for one prayer on one day: `2026-09-21_maghrib`.
  ///
  /// This is the granularity every per-occurrence decision (mute, adhan on/off)
  /// is stored at — a user who silences tonight's Maghrib still wants tomorrow's.
  static String occurrenceId(DateTime date, PrayerKind kind) =>
      '${_dayStamp(date)}_${id(kind)}';

  /// Parses an [occurrenceId] back into its date and prayer. `null` when the
  /// value is malformed, which is how stale mute entries from a previous
  /// install get filtered out.
  static (DateTime, PrayerKind)? parseOccurrence(String occurrence) {
    final split = occurrence.lastIndexOf('_');
    if (split <= 0 || split == occurrence.length - 1) return null;
    final kind = fromId(occurrence.substring(split + 1));
    if (kind == null) return null;
    final date = DateTime.tryParse(occurrence.substring(0, split));
    if (date == null) return null;
    return (date, kind);
  }

  /// `yyyy-MM-dd` in local time.
  ///
  /// Deliberately manual rather than `DateFormat`: this string is a storage key,
  /// and its format must not shift with the active locale or a Hijri/Islamic
  /// calendar default — the same day would land under two different keys.
  static String _dayStamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
