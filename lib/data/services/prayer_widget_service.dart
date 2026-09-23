import 'package:flutter/foundation.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

/// Pushes the current prayer day to the Android home-screen widget.
///
/// The widget is a static snapshot rendered by generated Glance code — a compact
/// 2×2 card showing the next prayer, a countdown and a day-progress bar. All
/// values are pre-formatted in Dart (the widget data API stores scalars only),
/// and the snapshot is refreshed at every prayer rollover + app launch rather
/// than on every tick, to keep battery usage flat.
abstract final class PrayerWidgetService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Length of the day-progress bar, matched to the widget's
  /// `progressFilled` / `progressRemaining` defaults. Filled is rendered as a
  /// solid track (`━`), remaining as a dotted rail (`·`) so progress reads at
  /// a glance on the compact widget.
  static const int _barLength = 12;
  static const String _barFilled = '━';
  static const String _barRemaining = '·';

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
      final nextIn = next.time.difference(now).isNegative
          ? Duration.zero
          : next.time.difference(now);

      // Day progress Fajr → next-day Fajr, rendered as a segmented bar where
      // the filled portion is a solid track and the rest a dotted rail.
      final fajr = day.prayer(PrayerKind.fajr)?.time ?? day.date;
      final window = day.nextDayFajr.difference(fajr);
      final ratio = window <= Duration.zero
          ? 0.0
          : (now.difference(fajr).inMilliseconds / window.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();
      final filled = (ratio * _barLength).round();

      await PrayerWidgetHomeWidget.saveData(
        locationShort: _shorten(locationShort ?? settings.cityName),
        nextPrayerName: next.kind.displayName,
        nextPrayerTime: TimeFormatter.clock(next.time),
        nextPrayerCountdown: 'in ${TimeFormatter.longCountdown(nextIn)}',
        progressFilled: _barFilled * filled,
        progressRemaining: _barRemaining * (_barLength - filled),
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
