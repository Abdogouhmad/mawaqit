import 'package:flutter/foundation.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/prayer_widget_snapshot.dart';
import 'package:mawaqit/l10n/ambient_l10n.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

/// Pushes the current prayer day to the Android home-screen widget.
///
/// The widget is a static snapshot rendered by generated Glance code — a
/// compact 2×2 or 4×2 card showing the location, the next prayer, its time, the
/// countdown and the five-dot daily sequence. All values are pre-formatted in
/// Dart (the widget data API stores scalars only), and the snapshot is refreshed
/// at every prayer rollover + app launch rather than on every tick, to keep
/// battery flat.
abstract final class PrayerWidgetService {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Sends [day]'s snapshot to the widget and asks the launcher to re-render.
  ///
  /// [locationShort] overrides the place label (e.g. a GPS fix's display name);
  /// otherwise [AppSettings.effectiveLocationName] is used. Android-only; every
  /// error is swallowed so the widget can never block scheduling (desktop dev,
  /// emulators and pre-first-launch have no host).
  static Future<void> sync(
    PrayerDay day,
    AppSettings settings, {
    String? locationShort,
  }) async {
    if (!_isAndroid) return;
    try {
      final now = DateTime.now();

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
      final l10n = AmbientL10n.instance;

      final darkTheme =
          settings.themeMode == AppThemeMode.dark ||
          (settings.themeMode == AppThemeMode.system &&
              PlatformDispatcher.instance.platformBrightness ==
                  Brightness.dark);

      final snapshot = PrayerWidgetSnapshot.build(
        day,
        settings,
        now,
        l10n,
        locationShort: locationShort,
        timeFormatterLocale: locale.languageCode,
        darkThemeEffective: darkTheme,
      );

      await PrayerWidgetHomeWidget.saveData(
        locationShort: snapshot.locationShort,
        nextPrayerName: snapshot.nextPrayerName,
        nextPrayerTime: snapshot.nextPrayerTime,
        nextPrayerCountdown: snapshot.nextPrayerCountdown,
        hijriDate: snapshot.hijriDate,
        amoled: snapshot.amoled,
        showHijri: snapshot.showHijri,
        showQuickActions: snapshot.showQuickActions,
        // Every flag is written on every snapshot. `IsActive` is checked before
        // `IsPast` in the generated Kotlin, so after Isha the highlight rolls
        // over onto tomorrow's Fajr while today's own Fajr stays marked past.
        fajrIsActive: snapshot.isActive(PrayerKind.fajr),
        fajrIsPast: snapshot.isPast(PrayerKind.fajr),
        dhuhrIsActive: snapshot.isActive(PrayerKind.dhuhr),
        dhuhrIsPast: snapshot.isPast(PrayerKind.dhuhr),
        asrIsActive: snapshot.isActive(PrayerKind.asr),
        asrIsPast: snapshot.isPast(PrayerKind.asr),
        maghribIsActive: snapshot.isActive(PrayerKind.maghrib),
        maghribIsPast: snapshot.isPast(PrayerKind.maghrib),
        ishaIsActive: snapshot.isActive(PrayerKind.isha),
        ishaIsPast: snapshot.isPast(PrayerKind.isha),
      );
      await PrayerWidgetHomeWidget.updateWidget();
    } catch (_) {
      // No widget host / plugin unavailable — the widget is best-effort.
    }
  }
}
