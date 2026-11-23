import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/calendar/hijri_calendar_data.dart';
import 'package:mawaqit/core/utils/hijri_dates.dart';

void main() {
  group('HijriCalendarData', () {
    test('monthOf and month agree on the Gregorian date', () {
      final date = DateTime(2026, 9, 21);
      final current = HijriCalendarData.monthOf(date);
      final view = HijriCalendarData.month(current.year, current.month);
      expect(view.contains(date), isTrue);
      expect(HijriDates.full(date).year, current.year);
      expect(HijriDates.full(date).month, current.month);
    });

    test('day count is 29 or 30 and Gregorian days are contiguous', () {
      for (final month in [1, 4, 9, 12]) {
        final view = HijriCalendarData.month(1448, month);
        expect(view.dayCount, anyOf(29, 30), reason: 'month $month');
        final first = view.gregorian(1);
        final last = view.gregorian(view.dayCount);
        expect(
          last.difference(first).inDays,
          view.dayCount - 1,
          reason: 'month $month',
        );
        expect(view.leadingBlanks, inInclusiveRange(0, 6));
      }
    });

    test('well-known events sit on their Umm al-Qura dates', () {
      final muharram = HijriCalendarData.month(1448, 1);
      expect(muharram.eventOn(1), HijriEvent.newYear);

      final ramadan = HijriCalendarData.month(1448, 9);
      expect(ramadan.eventOn(1), HijriEvent.ramadan);
      expect(ramadan.eventOn(2), isNull);

      final hijjah = HijriCalendarData.month(1448, 12);
      expect(hijjah.eventOn(10), HijriEvent.eidAlAdha);
    });

    test('paging rolls the year over and clamps to the supported range', () {
      expect(HijriCalendarData.next(1448, 12), (year: 1449, month: 1));
      expect(HijriCalendarData.previous(1448, 1), (year: 1447, month: 12));
      expect(
        HijriCalendarData.month(HijriCalendarData.maxYear + 100, 1).year,
        HijriCalendarData.maxYear,
      );
    });
  });
}
