import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';

void main() {
  const repo = PrayerTimesRepository();

  PrayerDay dayFor(DateTime date, CalculationParameters parameters) =>
      repo.forDate(
        date: date,
        latitude: 35.7750,
        longitude: -78.6336,
        parameters: parameters,
      );

  test('computes an ordered schedule for the five prayers', () {
    final day = dayFor(
      DateTime(2015, 7, 12),
      CalculationMethodParameters.northAmerica(),
    );

    expect(day.prayers.length, 5);
    expect(day.prayers.map((p) => p.kind), PrayerKind.five);

    final t = day.prayers.map((p) => p.time).toList();
    for (var i = 0; i < t.length - 1; i++) {
      expect(
        t[i].isBefore(t[i + 1]),
        isTrue,
        reason:
            '${day.prayers[i].kind} must precede ${day.prayers[i + 1].kind}',
      );
    }
    expect(day.sunrise.isAfter(day.prayers.first.time), isTrue);
    expect(day.sunset.isBefore(day.prayer(PrayerKind.isha)!.time), isTrue);
  });

  test('solar noon equals Dhuhr', () {
    final day = dayFor(
      DateTime(2026, 9, 21),
      CalculationMethodParameters.muslimWorldLeague(),
    );
    expect(day.solarNoon, day.prayer(PrayerKind.dhuhr)!.time);
  });

  test('next day Fajr carries into tomorrow', () {
    final day = dayFor(
      DateTime(2015, 7, 12),
      CalculationMethodParameters.ummAlQura(),
    );
    expect(day.nextDayFajr.isAfter(day.prayer(PrayerKind.isha)!.time), isTrue);
  });

  test('short label exposes the calculation angle', () {
    final label = PrayerTimesRepository.shortLabel(CalculationMethod.ummAlQura);
    expect(label.toLowerCase(), contains('umm al-qura'));
    expect(label, contains('18.5°'));
  });

  test('different madhabs shift Asr', () {
    final standard = dayFor(
      DateTime(2015, 7, 12),
      CalculationMethodParameters.northAmerica(),
    ).prayer(PrayerKind.asr)!.time;

    final hanafi = dayFor(
      DateTime(2015, 7, 12),
      CalculationMethodParameters.northAmerica()..madhab = Madhab.hanafi,
    ).prayer(PrayerKind.asr)!.time;

    expect(hanafi.isAfter(standard) || hanafi == standard, isTrue);
  });
}
