import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/prayer_widget_snapshot.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final base = DateTime(2026, 9, 21, 12, 30);
  final day = PrayerDay(
    date: DateTime(2026, 9, 21),
    prayers: [
      PrayerTime(kind: PrayerKind.fajr, time: DateTime(2026, 9, 21, 5, 10)),
      PrayerTime(kind: PrayerKind.dhuhr, time: DateTime(2026, 9, 21, 12)),
      PrayerTime(kind: PrayerKind.asr, time: DateTime(2026, 9, 21, 15, 40)),
      PrayerTime(kind: PrayerKind.maghrib, time: DateTime(2026, 9, 21, 18, 25)),
      PrayerTime(kind: PrayerKind.isha, time: DateTime(2026, 9, 21, 19, 55)),
    ],
    sunrise: DateTime(2026, 9, 21, 6, 30),
    sunset: DateTime(2026, 9, 21, 18, 25),
    solarNoon: DateTime(2026, 9, 21, 12),
    nextDayFajr: DateTime(2026, 9, 22, 5, 9),
    methodName: 'test',
  );

  PrayerWidgetSnapshot build(
    AppSettings settings, {
    String? location,
    String locale = 'en',
    bool dark = false,
  }) => PrayerWidgetSnapshot.build(
    day,
    settings,
    base,
    lookupAppLocalizations(Locale(locale)),
    locationShort: location,
    timeFormatterLocale: locale,
    darkThemeEffective: dark,
  );

  test('next prayer, countdown and sequence come from the day', () {
    final snapshot = build(const AppSettings());
    expect(snapshot.activeKind, PrayerKind.asr);
    expect(snapshot.isPast(PrayerKind.fajr), isTrue);
    expect(snapshot.isPast(PrayerKind.dhuhr), isTrue);
    expect(snapshot.isPast(PrayerKind.asr), isFalse);
    expect(snapshot.nextPrayerCountdown, contains('3'));
  });

  test('location label is shortened without touching the saved city', () {
    const settings = AppSettings(
      locationMode: LocationMode.city,
      cityName: 'Rabat, Morocco',
    );
    final snapshot = build(settings, location: 'Halifax, NS, Canada');
    expect(snapshot.locationShort, 'Halifax');
    expect(settings.cityName, 'Rabat, Morocco');

    expect(build(settings).locationShort, 'Rabat');
  });

  test('AMOLED applies only when dark theme is actually in effect', () {
    const settings = AppSettings(amoled: true, themeMode: AppThemeMode.dark);
    expect(build(settings, dark: true).amoled, isTrue);
    expect(build(settings).amoled, isFalse);

    const light = AppSettings(amoled: true, themeMode: AppThemeMode.light);
    expect(build(light).amoled, isFalse);
  });

  test('visibility flags round-trip from settings', () {
    const settings = AppSettings(
      widgetShowHijri: false,
      widgetShowQuickActions: false,
    );
    final snapshot = build(settings);
    expect(snapshot.showHijri, isFalse);
    expect(snapshot.showQuickActions, isFalse);
    expect(snapshot.hijriDate, isNotEmpty);
  });

  test('Hijri month names follow the widget locale', () {
    final english = build(const AppSettings());
    final arabic = build(const AppSettings(), locale: 'ar');
    expect(english.hijriDate, isNot(arabic.hijriDate));
  });
}
