import 'package:adhan_dart/adhan_dart.dart';

import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';

/// Wraps the offline `adhan_dart` calculation engine and maps results to
/// clean domain models.
class PrayerTimesRepository {
  const PrayerTimesRepository();

  static final Map<CalculationMethod, String> _angles = {
    CalculationMethod.muslimWorldLeague: '18.0° / 17.0°',
    CalculationMethod.northAmerica: '15.0° / 15.0°',
    CalculationMethod.ummAlQura: '18.5°',
    CalculationMethod.egyptian: '19.5° / 17.5°',
    CalculationMethod.karachi: '18.0° / 18.0°',
    CalculationMethod.tehran: '17.7° / 14.0°',
    CalculationMethod.france: '12.0° / 12.0°',
    CalculationMethod.turkiye: '18.0° / 17.0°',
    CalculationMethod.morocco: '19.0° / 17.0°',
    CalculationMethod.russia: '16.0° / 15.0°',
    CalculationMethod.gulfRegion: '19.5°',
    CalculationMethod.kuwait: '18.0° / 17.5°',
    CalculationMethod.qatar: '18.0°',
    CalculationMethod.singapore: '20.0° / 18.0°',
    CalculationMethod.indonesian: '20.0° / 18.0°',
  };

  /// Human-friendly method label used in the UI footer. For the marker used
  /// on home ("Umm al-Qura (18.5°)" style), see [shortLabel].
  static String methodLabel(CalculationMethod method) => method.displayName;

  static String shortLabel(CalculationMethod method) {
    final angle = _angles[method];
    return angle == null ? method.displayName : '${method.displayName} ($angle)';
  }

  PrayerDay forDate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required CalculationParameters parameters,
  }) {
    final times = PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: parameters,
    );

    return PrayerDay(
      date: date,
      prayers: [
        for (final kind in PrayerKind.five)
          PrayerTime(kind: kind, time: times.timeForPrayer(kind.toAdhan())),
      ],
      sunrise: times.sunrise,
      sunset: times.sunset,
      solarNoon: times.dhuhr,
      nextDayFajr: times.fajrAfter,
      methodName: shortLabel(parameters.method),
    );
  }

  /// Convenience label with the calculation angle, used on home screen.
  String methodLabelWithTime(CalculationMethod method) =>
      TimeFormatter.methodLabelWithAngle(method.displayName, _angles[method]);
}