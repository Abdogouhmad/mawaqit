import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/core/insights/prayer_insights.dart';
import 'package:mawaqit/data/models/prayer_history.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

void main() {
  final now = DateTime(2026, 9, 21, 20);

  PrayerHistoryEntry entry(String id, {bool onTime = true}) =>
      PrayerHistoryEntry(occurrenceId: id, markedAt: now, onTime: onTime);

  group('PrayerInsights.forMonth', () {
    test('empty history has no numbers and no streak', () {
      final summary = PrayerInsights.forMonth(const [], now);
      expect(summary.isEmpty, isTrue);
      expect(summary.total, 0);
      expect(summary.onTimePercent, isNull);
      expect(summary.streakDays, 0);
    });

    test('only the requested month counts toward the total', () {
      final summary = PrayerInsights.forMonth([
        entry(PrayerKeys.occurrenceId(DateTime(2026, 9), PrayerKind.fajr)),
        entry(
          PrayerKeys.occurrenceId(DateTime(2026, 9, 20), PrayerKind.maghrib),
          onTime: false,
        ),
        entry(PrayerKeys.occurrenceId(DateTime(2026, 8, 31), PrayerKind.isha)),
      ], now);
      expect(summary.total, 2);
      expect(summary.onTimePercent, 50);
    });

    test('a streak survives a day with no mark only for one day', () {
      final summary = PrayerInsights.forMonth(
        [
          entry(
            PrayerKeys.occurrenceId(DateTime(2026, 9, 20), PrayerKind.fajr),
          ),
          entry(PrayerKeys.occurrenceId(DateTime(2026, 9, 19), PrayerKind.asr)),
          entry(
            PrayerKeys.occurrenceId(DateTime(2026, 9, 18), PrayerKind.isha),
          ),
        ],
        // Today has no mark yet, so the streak must start from yesterday.
        now,
      );
      expect(summary.streakDays, 3);

      final broken = PrayerInsights.forMonth([
        entry(PrayerKeys.occurrenceId(DateTime(2026, 9, 20), PrayerKind.fajr)),
        entry(PrayerKeys.occurrenceId(DateTime(2026, 9, 18), PrayerKind.isha)),
      ], now);
      expect(broken.streakDays, 1);
    });

    test('malformed occurrence ids are skipped, not thrown', () {
      final summary = PrayerInsights.forMonth([
        entry('garbage'),
        entry('2026-09-21_not-a-prayer'),
        entry(PrayerKeys.occurrenceId(DateTime(2026, 9, 21), PrayerKind.dhuhr)),
      ], now);
      expect(summary.total, 1);
    });
  });
}
