import 'package:flutter/foundation.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

/// Pushes the current prayer day to the Android home-screen widget.
///
/// The widget is a static snapshot rendered by generated Glance code — a
/// compact 2×2 card showing the location, the next prayer, its time and the
/// countdown until it. All values are pre-formatted in Dart (the widget data
/// API stores scalars only), and the snapshot is refreshed at every prayer
/// rollover + app launch rather than on every tick, to keep battery flat.
abstract final class PrayerWidgetService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Sends [day]'s snapshot to the widget and asks the launcher to re-render.
  ///
  /// [locationShort] overrides the place label (e.g. a GPS fix's display name);
  /// otherwise [AppSettings.cityName] is used. Android-only; every error is
  /// swallowed so the widget can never block scheduling (desktop dev,
  /// emulators and pre-first-launch have no host).
  static Future<void> sync(
    PrayerDay day,
    AppSettings settings, {
    String? locationShort,
  }) async {
    if (!_isAndroid) return;
    try {
      final now = DateTime.now();

      // Next prayer — or tomorrow's Fajr once today is fully over.
      PrayerTime next =
          day.currentOrNextPrayer(now) ??
          PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
      final remaining = next.time.difference(now);
      final nextIn = remaining.isNegative ? Duration.zero : remaining;

      await PrayerWidgetHomeWidget.saveData(
        locationShort: _shorten(locationShort ?? settings.cityName),
        nextPrayerName: next.kind.displayName,
        nextPrayerTime: TimeFormatter.clock(next.time),
        nextPrayerCountdown: 'in ${TimeFormatter.longCountdown(nextIn)}',
      );
      await PrayerWidgetHomeWidget.updateWidget();
    } catch (_) {
      // No widget host / plugin unavailable — the widget is best-effort.
    }
  }

  /// First comma-separated part of a place name ("Halifax, NS, Canada" →
  /// "Halifax"), dropped to the "—" placeholder when empty.
  static String _shorten(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final first = raw.split(',').first.trim();
    return first.isEmpty ? '—' : first;
  }
}
