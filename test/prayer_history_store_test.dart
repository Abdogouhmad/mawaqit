import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/prayer_history.dart';
import 'package:mawaqit/data/repositories/prayer_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('JSON round-trip preserves every mark field', () {
    final entry = PrayerHistoryEntry(
      occurrenceId: '2026-09-21_maghrib',
      markedAt: DateTime(2026, 9, 21, 18, 30),
      onTime: true,
    );
    final decoded = PrayerHistoryEntry.fromJson(entry.toJson());
    expect(decoded, isNotNull);
    expect(decoded!.occurrenceId, entry.occurrenceId);
    expect(decoded.markedAt, entry.markedAt);
    expect(decoded.onTime, entry.onTime);
  });

  test('malformed rows are rejected instead of throwing', () {
    expect(PrayerHistoryEntry.fromJson({'id': 7, 'at': 'nope'}), isNull);
    expect(
      PrayerHistoryEntry.fromJson({'id': 'x', 'at': 'not-a-date'}),
      isNull,
    );
  });

  test('toggle adds, removes and computes the on-time flag', () async {
    final store = PrayerHistoryStore();
    final now = DateTime(2026, 9, 21, 18, 35);
    final time = DateTime(2026, 9, 21, 18, 25);

    final added = await store.toggle(
      '2026-09-21_maghrib',
      now: now,
      prayerTime: time,
    );
    expect(added, hasLength(1));
    expect(added.single.onTime, isTrue);

    final lateMark = await store.toggle(
      '2026-09-21_isha',
      now: now.add(const Duration(hours: 3)),
      prayerTime: time,
    );
    expect(lateMark.first.onTime, isFalse);

    final removed = await store.toggle(
      '2026-09-21_maghrib',
      now: now,
      prayerTime: time,
    );
    expect(removed.map((e) => e.occurrenceId), ['2026-09-21_isha']);
  });

  test('history is bounded on write', () async {
    final store = PrayerHistoryStore();
    final now = DateTime(2026, 9, 21);
    final entries = [
      for (var i = 0; i < PrayerHistoryStore.maxEntries + 20; i++)
        PrayerHistoryEntry(
          occurrenceId: '2026-09-21_prayer$i',
          markedAt: now.add(Duration(seconds: i)),
          onTime: true,
        ),
    ];
    final saved = await store.save(entries);
    expect(saved, hasLength(PrayerHistoryStore.maxEntries));
    expect((await store.load()), hasLength(PrayerHistoryStore.maxEntries));
  });
}
