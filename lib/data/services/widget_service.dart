import 'package:home_widget/home_widget.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

/// Pushes the small "next prayer" home-screen card (Android Glance widget).
///
/// Data is written to `home_widget`'s SharedPreferences bridge and the widget
/// is told to re-render via `HomeWidget.updateWidget`. The countdown is a
/// static snapshot refreshed on each push — never a live timer inside the
/// widget (see FEAT spec).
class WidgetService {
  static const String _androidName = 'PrayerWidgetReceiver';
  static const String _androidQualified =
      'com.mawaqit.mawaqit.PrayerWidgetReceiver';

  /// Writes a neutral snapshot as soon as the app starts so a freshly added
  /// widget on a launcher that hasn't been fed data yet (or one that resets
  /// the bridge prefs) is never a blank card. Replaced by the real snapshot
  /// on the next [updateWidget] push from the home controller.
  static Future<void> pushPlaceholder() {
    return updateWidget();
  }

  /// Sends the current next-prayer snapshot to the home-screen widget.
  static Future<void> updateWidget({
    PrayerTime? nextPrayer,
    PrayerTime? currentPrayer,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    try {
      if (nextPrayer == null) {
        await HomeWidget.saveWidgetData<String>('next_prayer_name', 'Mawaqit');
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          'Loading prayer times…',
        );
        await HomeWidget.saveWidgetData<int>('minutes_remaining', -1);
        await HomeWidget.saveWidgetData<double>('progress', 0);
      } else {
        final start =
            currentPrayer?.time ?? DateTime(at.year, at.month, at.day);
        final duration = nextPrayer.time.difference(start).inSeconds;
        final elapsed = at.difference(start).inSeconds;
        final progress = duration <= 0
            ? 0.0
            : (elapsed / duration).clamp(0.0, 1.0);

        await HomeWidget.saveWidgetData<String>(
          'next_prayer_name',
          nextPrayer.kind.displayName,
        );
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          TimeFormatter.clock(nextPrayer.time),
        );
        await HomeWidget.saveWidgetData<int>(
          'minutes_remaining',
          nextPrayer.time.difference(at).inMinutes.clamp(0, 0x7FFFFFFF).toInt(),
        );
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
}