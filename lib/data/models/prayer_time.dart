import 'package:adhan_dart/adhan_dart.dart';

/// The five obligatory prayers plus auxiliary markers.
///
/// Deliberately carries **no** display name. Prayer labels are locale-dependent,
/// so they live in `PrayerKindL10n` (lib/l10n/enum_localization.dart) rather than
/// on the enum — putting an English `displayName` here is what previously forced
/// the whole UI to English.
enum PrayerKind {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  static const List<PrayerKind> five = [
    PrayerKind.fajr,
    PrayerKind.dhuhr,
    PrayerKind.asr,
    PrayerKind.maghrib,
    PrayerKind.isha,
  ];

  Prayer toAdhan() => switch (this) {
    PrayerKind.fajr => Prayer.fajr,
    PrayerKind.dhuhr => Prayer.dhuhr,
    PrayerKind.asr => Prayer.asr,
    PrayerKind.maghrib => Prayer.maghrib,
    PrayerKind.isha => Prayer.isha,
  };
}

/// A single prayer entry within a day's schedule.
class PrayerTime {
  const PrayerTime({required this.kind, required this.time});

  final PrayerKind kind;
  final DateTime time;
}

/// Immutable, fully-resolved daily prayer schedule (domain model).
class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.prayers,
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.nextDayFajr,
    required this.methodName,
  });

  final DateTime date;
  final List<PrayerTime> prayers;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final DateTime nextDayFajr;
  final String methodName;

  PrayerTime? prayer(PrayerKind kind) {
    for (final p in prayers) {
      if (p.kind == kind) return p;
    }
    return null;
  }

  PrayerTime? currentOrNextPrayer(DateTime now) {
    for (final p in prayers) {
      if (!p.time.isAfter(now)) continue;
      return p;
    }
    return null;
  }
}
