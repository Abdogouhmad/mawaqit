import 'package:flutter/foundation.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/l10n/ambient_l10n.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
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

      // This also runs from the WorkManager isolate, which has no widget tree
      // and therefore never ran the app builder that normally records the
      // locale. Re-apply the user's choice from [settings] here, or a user who
      // picked a language different from the device's would get a widget in the
      // device language. `TimeFormatter` needs the same nudge for its clock.
      final locale = resolveAppLocale(
        settings.language,
        PlatformDispatcher.instance.locale,
      );
      AmbientL10n.locale = locale;
      TimeFormatter.locale(locale.languageCode);
      final l10n = AmbientL10n.instance;

      // Whether a prayer's time has already gone by today.
      bool isPast(PrayerKind kind) {
        final t = day.prayer(kind)?.time;
        return t != null && t.isBefore(now);
      }

      await PrayerWidgetHomeWidget.saveData(
        locationShort: _shorten(locationShort ?? settings.cityName),
        nextPrayerName: next.kind.localized(l10n),
        nextPrayerTime: TimeFormatter.clock(next.time),
        nextPrayerCountdown: l10n.widgetIn(TimeFormatter.longCountdown(nextIn)),
        // The five prayer-sequence dots.
        //
        // These ten flags used to be omitted here, and the omission was silent:
        // the generated `saveData` skips every null argument, and the generated
        // `PrayerWidgetData.fromPreferences` collapses a *missing* key to
        // `false` — the same value the widget reads for "not past". So nothing
        // ever threw and nothing ever looked broken; all five dots just sat at
        // the faintest tint forever and the row never moved.
        //
        // Every flag is therefore written on every snapshot. `IsActive` is
        // checked before `IsPast` in the generated Kotlin, so after Isha the
        // highlight correctly rolls over onto tomorrow's Fajr — `next.kind`
        // becomes fajr above, while today's own Fajr stays marked past.
        fajrIsActive: next.kind == PrayerKind.fajr,
        fajrIsPast: isPast(PrayerKind.fajr),
        dhuhrIsActive: next.kind == PrayerKind.dhuhr,
        dhuhrIsPast: isPast(PrayerKind.dhuhr),
        asrIsActive: next.kind == PrayerKind.asr,
        asrIsPast: isPast(PrayerKind.asr),
        maghribIsActive: next.kind == PrayerKind.maghrib,
        maghribIsPast: isPast(PrayerKind.maghrib),
        ishaIsActive: next.kind == PrayerKind.isha,
        ishaIsPast: isPast(PrayerKind.isha),
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
