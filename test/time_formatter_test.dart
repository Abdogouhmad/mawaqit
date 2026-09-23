import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter.countdown', () {
    test('composes hours and minutes', () {
      expect(TimeFormatter.countdown(const Duration(hours: 1, minutes: 24)),
          '1h 24m 00s');
    });

    test('shows only minutes under an hour', () {
      expect(TimeFormatter.countdown(const Duration(minutes: 42)),
          '42m 00s');
    });

    test('shows seconds under a minute', () {
      expect(TimeFormatter.countdown(const Duration(seconds: 12)), '12s');
    });

    test('includes days when crossing midnight', () {
      expect(TimeFormatter.countdown(const Duration(days: 1, hours: 3)),
          '1d 3h 0m 00s');
    });
  });

  group('TimeFormatter.clock', () {
    test('formats 12-hour time with meridiem', () {
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 13, 48)), '1:48 PM');
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 5, 30)), '5:30 AM');
    });
  });

  group('TimeFormatter.dayLength', () {
    test('formats duration as hours and minutes', () {
      expect(TimeFormatter.dayLength(const Duration(hours: 11, minutes: 14)),
          '11h 14m');
    });
  });
}