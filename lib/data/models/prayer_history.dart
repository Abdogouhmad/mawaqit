import 'package:flutter/foundation.dart';

/// One manual "I prayed" mark.
///
/// Deliberately carries no device id, account, location or free text: the only
/// data is the occurrence key the app already uses for notification mutes and
/// when the user tapped. Nothing here is ever sent anywhere.
@immutable
class PrayerHistoryEntry {
  const PrayerHistoryEntry({
    required this.occurrenceId,
    required this.markedAt,
    required this.onTime,
  });

  final String occurrenceId;
  final DateTime markedAt;

  /// Whether the mark landed within the on-time window of that prayer. Computed
  /// once at mark time, while the schedule for that occurrence is still at
  /// hand; insights stay a pure function of these immutable entries.
  final bool onTime;

  Map<String, dynamic> toJson() => {
    'id': occurrenceId,
    'at': markedAt.toIso8601String(),
    'onTime': onTime,
  };

  static PrayerHistoryEntry? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final at = json['at'];
    if (id is! String || at is! String) return null;
    final parsed = DateTime.tryParse(at);
    if (parsed == null) return null;
    return PrayerHistoryEntry(
      occurrenceId: id,
      markedAt: parsed,
      onTime: json['onTime'] == true,
    );
  }
}
