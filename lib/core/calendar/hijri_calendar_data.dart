import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mawaqit/core/utils/hijri_dates.dart';

/// The well-known dates the calendar marks. Only these five are shown: a grid
/// sprinkled with dozens of commemorations stops being a calendar and starts
/// being a almanac nobody asked for. Each entry is (Hijri month, Hijri day).
enum HijriEvent {
  newYear(1, 1),
  mawlid(3, 12),
  ramadan(9, 1),
  eidAlFitr(10, 1),
  eidAlAdha(12, 10);

  const HijriEvent(this.month, this.day);

  /// Hijri month, 1–12 (Muharram … Dhu al-Hijjah).
  final int month;

  /// Day within that month.
  final int day;
}

/// One Hijri month laid out on a Gregorian week grid.
///
/// All conversions are delegated to [HijriDates] (fromDate) and the `hijri`
/// package's Umm al-Qura tables (hijriToGregorian/getDaysInMonth), which are
/// 1-based for months. The widget only receives immutable scalars, so paging,
/// highlighting and event lookup can be unit-tested without pumping a screen.
@immutable
class HijriMonthView {
  const HijriMonthView({
    required this.year,
    required this.month,
    required this.firstDay,
    required this.dayCount,
    required this.leadingBlanks,
    required this.events,
  });

  /// Hijri year, e.g. 1448.
  final int year;

  /// Hijri month, 1–12.
  final int month;

  /// Gregorian date of Hijri day 1 of this month.
  final DateTime firstDay;

  /// Number of days in this Hijri month (29 or 30).
  final int dayCount;

  /// Empty cells before day 1 in a Monday-first week grid, 0–6.
  final int leadingBlanks;

  /// Well-known events in this month, in day order.
  final List<HijriEvent> events;

  /// Gregorian date of a Hijri day (1-based) in this month.
  DateTime gregorian(int day) => firstDay.add(Duration(days: day - 1));

  /// The event on [day], if any.
  HijriEvent? eventOn(int day) {
    for (final event in events) {
      if (event.day == day) return event;
    }
    return null;
  }

  /// Whether [date] is one of this month's days.
  bool contains(DateTime date) {
    final difference = _dayDiff(firstDay, date);
    return difference >= 0 && difference < dayCount;
  }

  static int _dayDiff(DateTime a, DateTime b) => DateTime(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime(a.year, a.month, a.day)).inDays;
}

abstract final class HijriCalendarData {
  const HijriCalendarData._();

  /// The `hijri` package's tables cover only this AH range. Outside it we must
  /// not pretend to know the answer, so callers clamp to it instead of allowing
  /// an out-of-range lookup to throw mid-build.
  static const int minYear = 1356;
  static const int maxYear = 1500;

  /// Builds the month view for a Hijri (year, month) pair, clamping the year.
  ///
  /// The constructor `HijriCalendar()` is cheap; its `hijriToGregorian` and
  /// `getDaysInMonth` are table lookups. Keeping the call in one pure function
  /// means a test can assert the Gregorian mapping and month length directly.
  static HijriMonthView month(int year, int month) {
    final clampedYear = year.clamp(minYear, maxYear);
    final clampedMonth = month.clamp(1, 12);
    final calendar = HijriCalendar();
    final first = calendar.hijriToGregorian(clampedYear, clampedMonth, 1);
    final dayCount = calendar.getDaysInMonth(clampedYear, clampedMonth);
    return HijriMonthView(
      year: clampedYear,
      month: clampedMonth,
      firstDay: DateTime(first.year, first.month, first.day),
      dayCount: dayCount,
      // DateTime.weekday: Monday = 1 … Sunday = 7. The grid starts on Monday.
      leadingBlanks: DateTime(first.year, first.month, first.day).weekday - 1,
      events: [
        for (final event in HijriEvent.values)
          if (event.month == clampedMonth) event,
      ],
    );
  }

  /// The Hijri month containing [date].
  static ({int year, int month}) monthOf(DateTime date) {
    final h = HijriDates.full(date);
    return (year: h.year, month: h.month);
  }

  /// The next Hijri month after [year]/[month], rolling the year over.
  static ({int year, int month}) next(int year, int month) =>
      month == 12 ? (year: year + 1, month: 1) : (year: year, month: month + 1);

  /// The previous Hijri month before [year]/[month], rolling the year back.
  static ({int year, int month}) previous(int year, int month) =>
      month == 1 ? (year: year - 1, month: 12) : (year: year, month: month - 1);
}
