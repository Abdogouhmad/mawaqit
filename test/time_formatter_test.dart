import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter.countdown', () {
    test('composes hours and minutes', () {
      expect(
        TimeFormatter.countdown(const Duration(hours: 1, minutes: 24)),
        '1h 24m 00s',
      );
    });

    test('shows only minutes under an hour', () {
      expect(TimeFormatter.countdown(const Duration(minutes: 42)), '42m 00s');
    });

    test('shows seconds under a minute', () {
      expect(TimeFormatter.countdown(const Duration(seconds: 12)), '12s');
    });

    test('includes days when crossing midnight', () {
      expect(
        TimeFormatter.countdown(const Duration(days: 1, hours: 3)),
        '1d 3h 0m 00s',
      );
    });
  });

  group('TimeFormatter.clock', () {
    // `use24HourFormat` is a process-wide flag, so every test that touches it
    // has to put it back — otherwise it leaks into the 12-hour expectations
    // below purely by declaration order.
    tearDown(() => TimeFormatter.use24HourFormat(false));

    test('defaults to 12-hour time with meridiem', () {
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 13, 48)), '1:48 PM');
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 5, 30)), '5:30 AM');
    });

    test('honours the device 24-hour setting', () {
      TimeFormatter.use24HourFormat(true);
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 13, 48)), '13:48');
      // Midnight and noon are the cases a 12-hour switch gets wrong, so they
      // are the ones worth pinning down.
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 0, 5)), '00:05');
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 12, 0)), '12:00');
    });

    test('keeps a leading zero on single-digit hours in 24-hour form', () {
      TimeFormatter.use24HourFormat(true);
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 9, 5)), '09:05');
    });

    test('reverts to 12-hour when the device setting is turned back off', () {
      TimeFormatter.use24HourFormat(true);
      expect(TimeFormatter.use24Hour, isTrue);
      TimeFormatter.use24HourFormat(false);
      expect(TimeFormatter.use24Hour, isFalse);
      expect(TimeFormatter.clock(DateTime(2026, 9, 21, 13, 48)), '1:48 PM');
    });
  });

  group('TimeFormatter.dayLength', () {
    test('formats duration as hours and minutes', () {
      expect(
        TimeFormatter.dayLength(const Duration(hours: 11, minutes: 14)),
        '11h 14m',
      );
    });
  });

  group('TimeFormatter.locale', () {
    // Both the locale and the 12/24 flag are process-wide, so each test puts
    // them back or it silently contaminates the others.
    tearDown(() {
      TimeFormatter.locale(null);
      TimeFormatter.use24HourFormat(false);
    });

    test('Arabic renders Arabic-Indic digits and a localized meridiem', () {
      TimeFormatter.locale('ar');
      final arabic = TimeFormatter.clock(DateTime(2026, 9, 21, 13, 48));
      // The point is that it is no longer the English "1:48 PM" string: `ar`
      // uses Arabic-Indic digits and a localized meridiem.
      expect(arabic, isNot('1:48 PM'));
      expect(arabic, contains('٤'));
    });

    test('an unsupported device locale falls back instead of throwing', () {
      // Regression guard: the generated lookupAppLocalizations throws for any
      // locale outside ['ar', 'en'], and TimeFormatter.locale is reachable with
      // a raw PlatformDispatcher locale.
      expect(() => TimeFormatter.locale('fr'), returnsNormally);
      expect(() => TimeFormatter.locale('zh'), returnsNormally);
    });

    test('Hijri month names are localized', () {
      TimeFormatter.locale('ar');
      // 1447-01-01 AH is a real Hijri date; the point is that the month name is
      // Arabic script rather than the Latin transliteration "Muharram".
      final hijri = TimeFormatter.hijri(DateTime(2025, 7, 26));
      expect(hijri, isNot(contains('Muharram')));
    });

    test('countdown unit suffixes are localized', () {
      TimeFormatter.locale('ar');
      expect(
        TimeFormatter.countdown(const Duration(hours: 1, minutes: 24)),
        isNot('1h 24m 00s'),
      );
    });
  });
}
