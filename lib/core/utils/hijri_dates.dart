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

  /// Conversions are memoised per calendar day.
  ///
  /// The Times tab converts every row it builds and the Home screen converts
  /// its date line; `HijriCalendar.fromDate` is comparatively expensive for a
  /// value that can only change once a day. The cache is bounded so paging a
  /// calendar for years cannot grow it without limit.
  static final Map<int, ({int day, int month, int year})> _cache = {};

  static ({int day, int month, int year}) _for(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length >= 4096) _cache.clear();

    final hijri = HijriCalendar.fromDate(date);
    final value = (day: hijri.hDay, month: hijri.hMonth, year: hijri.hYear);
    _cache[key] = value;
    return value;
  }

  /// The Hijri day-of-month for [date], 1–30.
  ///
  /// Umm al-Qura, the civil calendar used in Saudi Arabia and the basis of most
  /// published prayer-timetable tables, rather than the observational Islamic
  /// calendar that can differ by a day.
  static int dayOfMonth(DateTime date) => _for(date).day;

  /// Hijri day and month for [date].
  static ({int day, int month}) of(DateTime date) {
    final hijri = _for(date);
    return (day: hijri.day, month: hijri.month);
  }

  /// Hijri day, month and year for [date].
  ///
  /// Kept separate from [of] so the existing `(day, month)` record stays the
  /// public shape callers already use.
  static ({int day, int month, int year}) full(DateTime date) => _for(date);

  /// Whether [date] falls in the same Hijri month as [other].
  ///
  /// Used to tell the user when a Gregorian month spans two Hijri months, which
  /// matters at the Ramadan and Dhul-Hijjah boundaries.
  static bool isSameHijriMonth(DateTime a, DateTime b) {
    final first = _for(a);
    final second = _for(b);
    return first.month == second.month && first.year == second.year;
  }
}
