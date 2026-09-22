import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

/// Pushes the small "next prayer" home-screen card (native Android RemoteViews
/// powered by [HomeWidget]`s SharedPreferences bridge).
///
/// Flutter remains the source of truth for prayer times. The widget never
/// calculates anything — it only consumes the snapshot pushed here: the full
/// upcoming schedule as absolute epoch-millisecond timestamps (so it can
/// advance to the next prayer and cross midnight even while the app is
/// killed) plus a flat mirror of the immediate target.
class WidgetService {
  static const String _androidName = 'PrayerWidgetProvider';
  static const String _androidQualified =
      'com.mawaqit.mawaqit.PrayerWidgetProvider';

  /// Writes a neutral snapshot as soon as the app starts so a freshly added
  /// widget on a launcher that hasn't been fed data yet is never a blank card.
  /// Replaced by the real snapshot on the next [updateWidget] push.
  static Future<void> pushPlaceholder() => updateWidget();

  /// Sends the current prayer snapshot to the home-screen widget.
  static Future<void> updateWidget({
    PrayerDay? day,
    PrayerTime? nextPrayer,
    PrayerTime? currentPrayer,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    try {
      if (day == null) {
        // Neutral placeholder before the first real snapshot lands.
        await HomeWidget.saveWidgetData<String>(
          'prayer_schedule',
          jsonEncode(<Object>[]),
        );
        await HomeWidget.saveWidgetData<String>('next_prayer_name', 'Mawaqit');
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          'Loading prayer times…',
        );
        await HomeWidget.saveWidgetData<int>('next_prayer_ts', 0);
        await HomeWidget.saveWidgetData<double>('progress', 0);
      } else {
        final next = nextPrayer ??
            PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
        await HomeWidget.saveWidgetData<String>(
          'prayer_schedule',
          jsonEncode(upcomingSchedule(day)),
        );
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_name',
          next.kind.displayName,
        );
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          TimeFormatter.clock(next.time),
        );
        await HomeWidget.saveWidgetData<int>(
          'next_prayer_ts',
          next.time.millisecondsSinceEpoch,
        );

        final start =
            currentPrayer?.time ?? DateTime(at.year, at.month, at.day);
        final duration = next.time.difference(start).inSeconds;
        final elapsed = at.difference(start).inSeconds;
        final progress =
            duration <= 0 ? 0.0 : (elapsed / duration).clamp(0.0, 1.0);
        await HomeWidget.saveWidgetData<double>('progress', progress);
      }

      await HomeWidget.updateWidget(
        androidName: _androidName,
        qualifiedAndroidName: _androidQualified,
      );
    } catch (_) {
      // Widget plugin missing (Linux/desktop or widgetless device) — ignore.
    }
  }

  /// Serialises an unambiguous, timezone-independent snapshot of the day:
  /// today's five prayers (kept in full so the widget knows which one just
  /// passed) plus tomorrow's Fajr, all as absolute epoch-millisecond
  /// timestamps. The widget picks the nearest future entry at render time.
  static List<Map<String, Object>> upcomingSchedule(PrayerDay day) => [
        for (final p in day.prayers)
          {'name': p.kind.displayName, 'ts': p.time.millisecondsSinceEpoch},
        {
          'name': PrayerKind.fajr.displayName,
          'ts': day.nextDayFajr.millisecondsSinceEpoch,
        },
      ];
}