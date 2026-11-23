import 'package:flutter/foundation.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/data/models/prayer_history.dart';

/// Aggregates local manual prayer marks into the three numbers the Times card
/// shows. Every computation here is a pure function of [history] plus a clock —
/// no repository, no `BuildContext`, no I/O — so the card itself can only ever
/// render a result that a test has already pinned down.
@immutable
class PrayerInsightSummary {
  const PrayerInsightSummary({
    required this.total,
    required this.onTimePercent,
    required this.streakDays,
  });

  /// Number of marks whose occurrence date falls in the requested month.
  final int total;

  /// Percentage of this month's marks made within the on-time window, or `null`
  /// when there are none. `null` is distinct from `0`: "nothing to say" must not
  /// read as "you never pray on time".
  final int? onTimePercent;

  /// Consecutive days ending today (or yesterday, before the first mark of the
  /// day) that have at least one mark. Zero before any history exists.
  final int streakDays;

  bool get isEmpty => total == 0 && streakDays == 0;
}

abstract final class PrayerInsights {
  const PrayerInsights._();

  /// Summarises [history] for the Gregorian calendar month containing [now].
  ///
  /// Only marks whose parsed occurrence date lies in that month count toward
  /// [PrayerInsightSummary.total]; the streak deliberately looks at all history
  /// because it is a property of consecutive days, not of an arbitrary month
  /// boundary. Malformed occurrence ids are skipped — a corrupt row must never
  /// take the Times tab down.
  static PrayerInsightSummary forMonth(
    Iterable<PrayerHistoryEntry> history,
    DateTime now,
  ) {
    var total = 0;
    var onTime = 0;
    final markedDays = <int>{};

    for (final entry in history) {
      final parsed = PrayerKeys.parseOccurrence(entry.occurrenceId);
      if (parsed == null) continue;
      final (date, _) = parsed;
      markedDays.add(_stamp(date));
      if (date.year == now.year && date.month == now.month) {
        total++;
        if (entry.onTime) onTime++;
      }
    }

    return PrayerInsightSummary(
      total: total,
      onTimePercent: total == 0 ? null : ((onTime * 100) / total).round(),
      streakDays: _streak(markedDays, now),
    );
  }

  /// Consecutive marked days ending at [today] (or the day before it).
  ///
  /// Starting from yesterday when today has no mark keeps a streak alive
  /// through the early hours; it is the same convention every habit tracker
  /// uses and avoids resetting the count at midnight for someone who prays
  /// Fajr shortly after waking.
  static int _streak(Set<int> markedDays, DateTime today) {
    if (markedDays.isEmpty) return 0;
    var day = DateTime(today.year, today.month, today.day);
    if (!markedDays.contains(_stamp(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    if (!markedDays.contains(_stamp(day))) return 0;

    var days = 0;
    while (markedDays.contains(_stamp(day))) {
      days++;
      day = day.subtract(const Duration(days: 1));
    }
    return days;
  }

  static int _stamp(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
