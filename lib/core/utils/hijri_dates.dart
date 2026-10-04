import 'package:hijri/hijri_calendar.dart';

/// Umm al-Qura Hijri conversion for the Times table.
///
/// Wraps the `hijri` package so the calendar conversion is one import away from
/// the UI rather than scattered through widgets, and so it can be tested without
/// pumping a widget.
///
/// Only the *numbers* come from the package. Its month and weekday names ship in
/// English and Arabic only, which would leave the French locale showing an
/// English or Arabic month — so anything user-facing is formatted here or through
/// `intl` instead. `feat.md` §10 asks for the Hijri date on this tab, and the
/// Gregorian date alone is genuinely hard to work from for the app's primary
/// audience.
abstract final class HijriDates {
  const HijriDates._();

  /// The Hijri day-of-month for [date], 1–30.
  ///
  /// Umm al-Qura, the civil calendar used in Saudi Arabia and the basis of most
  /// published prayer-timetable tables, rather than the observational Islamic
  /// calendar that can differ by a day.
  static int dayOfMonth(DateTime date) => HijriCalendar.fromDate(date).hDay;

  /// Hijri day and month for [date].
  static ({int day, int month}) of(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return (day: hijri.hDay, month: hijri.hMonth);
  }

  /// Whether [date] falls in the same Hijri month as [other].
  ///
  /// Used to tell the user when a Gregorian month spans two Hijri months, which
  /// matters at the Ramadan and Dhul-Hijjah boundaries.
  static bool isSameHijriMonth(DateTime a, DateTime b) {
    final first = HijriCalendar.fromDate(a);
    final second = HijriCalendar.fromDate(b);
    return first.hMonth == second.hMonth && first.hYear == second.hYear;
  }
}
