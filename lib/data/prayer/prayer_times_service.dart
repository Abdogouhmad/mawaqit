import 'package:adhan_dart/adhan_dart.dart';

import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';

/// Multi-day prayer-time computation, on top of [PrayerTimesRepository]'s
/// single-day [PrayerTimesRepository.forDate].
///
/// Two things live here that the daily path does not need:
///
///  * **the month view** (feat.md §10), which is a *table* — 31 rows × 6
///    columns — so the result is computed in one pass rather than by a
///    repository call per cell;
///  * **the 14-day scheduling window** (feat.md §3), which needs future days but
///    must not walk past midnight: a day's Isha can land after 00:00 on the
///    following calendar date in some methods, so the window is built from
///    local midnights and read by timestamp, never by day index.
class PrayerTimesService {
  const PrayerTimesService();

  /// Every prayer for each day of [month], in calendar order.
  ///
  /// [month] is normalised to midnight on the 1st, so callers can pass
  /// `DateTime(2026, 9)` directly. Days before [today] are still computed —
  /// the monthly table shows the whole month, past days included.
  List<PrayerDay> forMonth({
    required DateTime month,
    required double latitude,
    required double longitude,
    required CalculationParameters parameters,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return [
      for (var day = 1; day <= daysInMonth; day++)
        PrayerTimesRepository().forDate(
          date: DateTime(month.year, month.month, day),
          latitude: latitude,
          longitude: longitude,
          parameters: parameters,
        ),
    ];
  }

  /// The next [days] days starting today, for alarm scheduling.
  ///
  /// Returns at most [days] entries and always starts at local midnight of
  /// [from], so index 0 is *today* even at 23:59.
  List<PrayerDay> window({
    required DateTime from,
    int days = 14,
    required double latitude,
    required double longitude,
    required CalculationParameters parameters,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    return [
      for (var offset = 0; offset < days; offset++)
        PrayerTimesRepository().forDate(
          date: start.add(Duration(days: offset)),
          latitude: latitude,
          longitude: longitude,
          parameters: parameters,
        ),
    ];
  }

  /// How many whole days of [days] still have at least one prayer time in the
  /// future.
  ///
  /// Used by the Reliability screen's "days remaining" warning. Counts from
  /// [now] rather than from the first entry, because a window that starts
  /// yesterday (a refresh at 00:01) still has most of its days ahead.
  int daysRemaining(List<PrayerDay> days, DateTime now) {
    final counted = <DateTime>{};
    for (final day in days) {
      for (final prayer in day.prayers) {
        if (prayer.time.isAfter(now)) {
          counted.add(day.date);
          break;
        }
      }
    }
    return counted.length;
  }
}
