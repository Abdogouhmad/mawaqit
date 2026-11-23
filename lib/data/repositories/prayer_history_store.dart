import 'dart:convert';

import 'package:mawaqit/core/const/pref_keys.dart';
import 'package:mawaqit/data/models/prayer_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only store for manual prayer marks.
///
/// Bounded on write so years of daily taps cannot grow the prefs blob without
/// limit. Corrupt entries are dropped individually rather than taking the whole
/// history (and therefore the Times tab) down.
class PrayerHistoryStore {
  static const int maxEntries = 500;

  /// Marks within this many minutes of the scheduled time count as on time.
  static const Duration onTimeWindow = Duration(minutes: 30);

  Future<List<PrayerHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.prayerHistory);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => PrayerHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .whereType<PrayerHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PrayerHistoryEntry>> save(
    Iterable<PrayerHistoryEntry> entries,
  ) async {
    final ordered = entries.toList()
      ..sort((a, b) => b.markedAt.compareTo(a.markedAt));
    final bounded = ordered.take(maxEntries).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefKeys.prayerHistory,
      jsonEncode(bounded.map((e) => e.toJson()).toList()),
    );
    return bounded;
  }

  /// Adds or removes [occurrenceId] and returns the new, ordered history.
  Future<List<PrayerHistoryEntry>> toggle(
    String occurrenceId, {
    required DateTime now,
    required DateTime prayerTime,
  }) async {
    final current = await load();
    if (current.any((e) => e.occurrenceId == occurrenceId)) {
      return save(current.where((e) => e.occurrenceId != occurrenceId));
    }
    final difference = now.difference(prayerTime).inMinutes.abs();
    final entry = PrayerHistoryEntry(
      occurrenceId: occurrenceId,
      markedAt: now,
      onTime: difference <= onTimeWindow.inMinutes,
    );
    return save([...current, entry]);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.prayerHistory);
  }
}
