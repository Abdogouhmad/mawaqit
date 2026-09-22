import 'package:flutter/foundation.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

/// Pushes the current prayer day to the Android home-screen widget.
///
/// The widget is a static snapshot rendered by generated Glance code: it shows
/// the five prayer times, the next prayer highlight and a countdown string. All
/// values are pre-formatted in Dart (the widget data API stores strings only),
/// and the countdown is refreshed at every prayer rollover + app launch rather
/// than on every tick, to keep battery usage flat.
abstract final class PrayerWidgetService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Sends [day]'s snapshot to the widget and asks the launcher to re-render.
  ///
  /// Android-only; every error is swallowed so the widget can never block
  /// scheduling (desktop dev, emulators and pre-first-launch have no host).
  static Future<void> sync(PrayerDay day) async {
    if (!_isAndroid) return;
    try {
      final now = DateTime.now();

      PrayerTime? next;
      for (final p in day.prayers) {
        if (p.time.isAfter(now)) {
          next = p;
          break;
        }
      }
      next ??= PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
      final nextIn = next.time.difference(now).isNegative
          ? Duration.zero
          : next.time.difference(now);

      String? nameOf(PrayerKind kind) => day.prayer(kind)?.kind.displayName;
      String? timeOf(PrayerKind kind) {
        final p = day.prayer(kind);
        return p == null ? null : TimeFormatter.clock(p.time);
      }

      await PrayerWidgetHomeWidget.saveData(
        nextPrayerName: next.kind.displayName,
        nextPrayerTime: TimeFormatter.clock(next.time),
        nextPrayerCountdown: 'in ${TimeFormatter.countdown(nextIn)}',
        fajrName: nameOf(PrayerKind.fajr),
        fajrTime: timeOf(PrayerKind.fajr),
        dhuhrName: nameOf(PrayerKind.dhuhr),
        dhuhrTime: timeOf(PrayerKind.dhuhr),
        asrName: nameOf(PrayerKind.asr),
        asrTime: timeOf(PrayerKind.asr),
        maghribName: nameOf(PrayerKind.maghrib),
        maghribTime: timeOf(PrayerKind.maghrib),
        ishaName: nameOf(PrayerKind.isha),
        ishaTime: timeOf(PrayerKind.isha),
      );
      await PrayerWidgetHomeWidget.updateWidget();
    } catch (_) {
      // No widget host / plugin unavailable — the widget is best-effort.
    }
  }
}