import 'package:flutter/foundation.dart';

import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// How many columns the month table draws: the five obligatory prayers plus
/// sunrise, in the order a monthly table reads — Fajr, sunrise, Dhuhr, Asr,
/// Maghrib, Isha.
///
/// Sunrise is the column the old five-prayer table dropped. It is not a prayer
/// and has no [PrayerKind], but the month has always been described as a
/// six-column table (`PrayerTimesService.forMonth`), and Fajr's window is the
/// reason a reader opens a monthly table at all.
const int timesColumnCount = 6;

/// The ordered column labels, shared by the pinned header and every [DayRow] so
/// the names and the values under them cannot drift.
List<String> timesColumnLabels(AppLocalizations l10n) => [
  PrayerKind.fajr.localized(l10n),
  l10n.timesSunrise,
  PrayerKind.dhuhr.localized(l10n),
  PrayerKind.asr.localized(l10n),
  PrayerKind.maghrib.localized(l10n),
  PrayerKind.isha.localized(l10n),
];

/// One cell of a day row: its label, the instant it names, and the [PrayerKind]
/// it belongs to.
///
/// [kind] is `null` for sunrise, which is a time without a prayer — modelling it
/// as a nullable kind rather than faking a sixth enum value keeps anything that
/// reasons about prayers (the "next prayer" highlight, scheduling, mute) from
/// ever seeing sunrise as one.
@immutable
class TimesColumn {
  const TimesColumn({required this.label, required this.time, this.kind});

  final String label;
  final DateTime time;
  final PrayerKind? kind;
}

/// The six columns of [day] in reading order.
List<TimesColumn> timesColumnsFor(PrayerDay day, AppLocalizations l10n) {
  final labels = timesColumnLabels(l10n);
  // The repository always resolves all five prayers, but a defensive fallback
  // to the day's own midnight keeps a malformed model from crashing the whole
  // month rather than blanking one cell.
  DateTime timeOf(PrayerKind kind) => day.prayer(kind)?.time ?? day.date;

  return [
    TimesColumn(
      label: labels[0],
      time: timeOf(PrayerKind.fajr),
      kind: PrayerKind.fajr,
    ),
    TimesColumn(label: labels[1], time: day.sunrise),
    TimesColumn(
      label: labels[2],
      time: timeOf(PrayerKind.dhuhr),
      kind: PrayerKind.dhuhr,
    ),
    TimesColumn(
      label: labels[3],
      time: timeOf(PrayerKind.asr),
      kind: PrayerKind.asr,
    ),
    TimesColumn(
      label: labels[4],
      time: timeOf(PrayerKind.maghrib),
      kind: PrayerKind.maghrib,
    ),
    TimesColumn(
      label: labels[5],
      time: timeOf(PrayerKind.isha),
      kind: PrayerKind.isha,
    ),
  ];
}
