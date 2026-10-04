import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/prayer/prayer_times_service.dart';

void main() {
  const service = PrayerTimesService();
  final parameters = CalculationMethodParameters.northAmerica();

  group('forMonth', () {
    test('returns one entry per day of the month, in calendar order', () {
      final days = service.forMonth(
        month: DateTime(2026, 2),
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

      expect(days.length, 28);
      expect(days.first.date, DateTime(2026, 2, 1));
      expect(days.last.date, DateTime(2026, 2, 28));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].date.isAfter(days[i - 1].date), isTrue);
      }
    });

    test('handles 30- and 31-day months and February in a leap year', () {
      int lengthOf(int year, int month) => service
          .forMonth(
            month: DateTime(year, month),
            latitude: 35.7750,
            longitude: -78.6336,
            parameters: parameters,
          )
          .length;

      expect(lengthOf(2026, 1), 31);
      expect(lengthOf(2026, 4), 30);
      expect(lengthOf(2026, 2), 28);
      expect(lengthOf(2028, 2), 29);
    });

    test('normalises a mid-month argument to the 1st', () {
      final fromFirst = service.forMonth(
        month: DateTime(2026, 2),
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );
      final fromMid = service.forMonth(
        month: DateTime(2026, 2, 17, 13, 45),
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

      expect(fromMid.length, fromFirst.length);
      expect(fromMid.first.date, fromFirst.first.date);
    });

    test('December does not roll the year over mid-table', () {
      final days = service.forMonth(
        month: DateTime(2026, 12),
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );
      expect(days.length, 31);
      expect(days.last.date, DateTime(2026, 12, 31));
      expect(days.every((d) => d.date.year == 2026), isTrue);
    });

    test('every entry carries all five prayers', () {
      final days = service.forMonth(
        month: DateTime(2026, 6),
        latitude: 21.4225,
        longitude: 39.8252,
        parameters: parameters,
      );
      expect(
        days.every((d) => d.prayers.length == 5),
        isTrue,
        reason: 'a month row must never be short a prayer',
      );
    });
  });

  group('window', () {
    test('starts at local midnight of the given day', () {
      final window = service.window(
        from: DateTime(2026, 3, 14, 23, 59),
        days: 3,
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

      expect(window.length, 3);
      expect(window.first.date, DateTime(2026, 3, 14));
      expect(window[1].date, DateTime(2026, 3, 15));
      expect(window[2].date, DateTime(2026, 3, 16));
    });

    test('crosses month and year boundaries without skipping a day', () {
      final window = service.window(
        from: DateTime(2026, 12, 30),
        days: 4,
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

      expect(window.map((d) => d.date).toList(), [
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 2),
      ]);
    });

    test('survives a DST transition without duplicating or dropping a day', () {
      // US spring-forward: 8 March 2026. A naive 24h step would land on 9 March
      // twice or skip 9 March entirely.
      final window = service.window(
        from: DateTime(2026, 3, 6),
        days: 6,
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

      final dates = window.map((d) => d.date).toList();
      expect(dates.length, 6);
      expect(dates.toSet().length, 6);
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].difference(dates[i - 1]).inDays, 1);
      }
    });

    test('defaults to a 14-day scheduling window', () {
      final window = service.window(
        from: DateTime(2026, 5, 1),
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );
      expect(window.length, 14);
    });
  });

  group('daysRemaining', () {
    final window = service.window(
      from: DateTime(2026, 5, 1),
      days: 14,
      latitude: 35.7750,
      longitude: -78.6336,
      parameters: parameters,
    );

    test('counts every day when now is before the window', () {
      expect(service.daysRemaining(window, DateTime(2026, 4, 30)), 14);
    });

    test('is zero once the whole window is in the past', () {
      expect(service.daysRemaining(window, DateTime(2026, 6, 1)), 0);
    });

    test('counts a day as remaining if any prayer is still ahead', () {
      final first = window.first;
      final justBeforeLastPrayer = first.prayers.last.time.subtract(
        const Duration(minutes: 1),
      );
      expect(
        service.daysRemaining(window, justBeforeLastPrayer),
        14,
        reason: 'the first day still has Isha ahead, so it counts',
      );
    });

    test('drops the current day once its last prayer has passed', () {
      final first = window.first;
      expect(
        service.daysRemaining(
          window,
          first.prayers.last.time.add(const Duration(minutes: 1)),
        ),
        13,
      );
    });

    test('is empty-input safe', () {
      expect(service.daysRemaining(const [], DateTime(2026, 5, 1)), 0);
    });
  });
}
