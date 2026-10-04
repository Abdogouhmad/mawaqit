import 'package:flutter_test/flutter_test.dart';

import 'package:mawaqit/core/utils/hijri_dates.dart';

/// Umm al-Qura conversion behind the Hijri column on the Times tab.
///
/// Anchored to published calendar transitions rather than to the package's own
/// output, so a change in its tables shows up here instead of silently shifting
/// every date in the table by a day.
void main() {
  group('dayOfMonth', () {
    // Gregorian -> Hijri dates of record for the Umm al-Qura calendar.
    final cases = <(String, DateTime, int)>[
      ('1 Muharram 1445', DateTime(2023, 7, 19), 1),
      ('1 Ramadan 1445', DateTime(2024, 3, 11), 1),
      ('1 Shawwal 1445 (Eid)', DateTime(2024, 4, 10), 1),
      ('1 Muharram 1447', DateTime(2025, 6, 26), 1),
      ('1 Ramadan 1447', DateTime(2026, 2, 18), 1),
      ('day 30 of a long month', DateTime(2024, 3, 30), 20),
    ];

    for (final (label, gregorian, expected) in cases) {
      test(
        '$label: ${gregorian.toIso8601String().substring(0, 10)} -> $expected',
        () {
          expect(HijriDates.dayOfMonth(gregorian), expected);
        },
      );
    }
  });

  group('of', () {
    test('reports day and month together', () {
      final hijri = HijriDates.of(DateTime(2026, 2, 18));
      expect(hijri.day, 1);
      expect(hijri.month, 9, reason: 'Ramadan is Hijri month 9');
    });
  });

  group('isSameHijriMonth', () {
    test('is true within one Hijri month', () {
      expect(
        HijriDates.isSameHijriMonth(
          DateTime(2026, 2, 18),
          DateTime(2026, 2, 28),
        ),
        isTrue,
      );
    });

    test('is false across the Ramadan boundary', () {
      expect(
        HijriDates.isSameHijriMonth(
          DateTime(2026, 2, 17),
          DateTime(2026, 2, 18),
        ),
        isFalse,
      );
    });
  });
}
