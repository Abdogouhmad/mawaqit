import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

void main() {
  test('every prayer has a frozen machine id that round-trips', () {
    for (final kind in PrayerKind.five) {
      expect(PrayerKeys.fromId(PrayerKeys.id(kind)), kind);
    }
    // These strings are persisted (notification ids, mute lists, native JSON),
    // so they must never be renamed without a migration.
    expect(PrayerKeys.id(PrayerKind.fajr), 'fajr');
    expect(PrayerKeys.id(PrayerKind.isha), 'isha');
  });

  test('fromId rejects anything unknown instead of throwing', () {
    expect(PrayerKeys.fromId('sunrise'), isNull);
    expect(PrayerKeys.fromId(''), isNull);
  });

  test('occurrenceId encodes the day and prayer', () {
    expect(
      PrayerKeys.occurrenceId(DateTime(2026, 9, 21), PrayerKind.maghrib),
      '2026-09-21_maghrib',
    );
  });

  test('occurrenceId zero-pads single-digit months and days', () {
    // The stamp is a storage key, so "2026-1-5" and "2026-01-05" must not both
    // be reachable — only the padded form is written.
    expect(
      PrayerKeys.occurrenceId(DateTime(2026, 1, 5), PrayerKind.fajr),
      '2026-01-05_fajr',
    );
  });

  test('parseOccurrence is the inverse of occurrenceId', () {
    final date = DateTime(2026, 9, 21);
    final parsed = PrayerKeys.parseOccurrence(
      PrayerKeys.occurrenceId(date, PrayerKind.asr),
    );

    expect(parsed, isNotNull);
    expect(parsed!.$1, date);
    expect(parsed.$2, PrayerKind.asr);
  });

  test('parseOccurrence drops malformed entries', () {
    // A stale or corrupt mute entry must be skipped, never crash the schedule.
    expect(PrayerKeys.parseOccurrence(''), isNull);
    expect(PrayerKeys.parseOccurrence('no-underscore'), isNull);
    expect(PrayerKeys.parseOccurrence('2026-09-21_'), isNull);
    expect(PrayerKeys.parseOccurrence('_maghrib'), isNull);
    expect(PrayerKeys.parseOccurrence('2026-09-21_sunrise'), isNull);
    expect(PrayerKeys.parseOccurrence('not-a-date_maghrib'), isNull);
  });

  test('parseOccurrence keeps the trailing token when the date has parts', () {
    // `lastIndexOf('_')` is deliberate: a hypothetically hyphenated date still
    // resolves its prayer from the final segment.
    final parsed = PrayerKeys.parseOccurrence('2026-09-21_isha');
    expect(parsed!.$2, PrayerKind.isha);
  });
}
