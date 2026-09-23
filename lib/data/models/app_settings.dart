import 'package:adhan_dart/adhan_dart.dart';

import 'package:mawaqit/data/models/notification_kind.dart';

enum AppThemeMode { system, light, dark }

/// Where prayer times derive coordinates from.
enum LocationMode {
  autoGps('Auto (GPS)'),
  city('City');

  const LocationMode(this.label);
  final String label;
}

/// Persisted user preferences (domain model).
class AppSettings {
  const AppSettings({
    this.calculationMethod = CalculationMethod.muslimWorldLeague,
    this.madhab = Madhab.shafi,
    this.leadMinutes = 10,
    this.prePrayerEnabled = true,
    this.adhanSoundEnabled = true,
    this.adhanTone = 'Adham Al Sharqawe',
    this.adhanDeviceToneUri,
    this.adhanDeviceToneName,
    this.preAlertTone = 'Silent',
    this.themeMode = AppThemeMode.system,
    this.locationMode = LocationMode.autoGps,
    this.cityName,
    this.cityLatitude,
    this.cityLongitude,
  });

  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final int leadMinutes; // 0 = none
  final bool prePrayerEnabled;
  final bool adhanSoundEnabled;
  final String adhanTone;

  /// Optional device ringtone / notification sound. When set it takes
  /// precedence over the bundled [adhanTone].
  final String? adhanDeviceToneUri;
  final String? adhanDeviceToneName;

  /// Bundled sound for the pre-prayer countdown card (its own channel).
  final String preAlertTone;

  final AppThemeMode themeMode;
  final LocationMode locationMode;
  final String? cityName;
  final double? cityLatitude;
  final double? cityLongitude;

  static const List<int> leadOptions = [0, 5, 10, 15];

  bool get hasCityCoordinates =>
      cityLatitude != null && cityLongitude != null;

  /// Whether a device sound overrides the bundled tone.
  bool get usesDeviceTone =>
      adhanDeviceToneUri != null && adhanDeviceToneUri!.isNotEmpty;

  /// Human-readable name of the currently selected alert sound.
  String get adhanLabel =>
      usesDeviceTone ? (adhanDeviceToneName ?? 'Device sound') : adhanTone;

  /// Human-readable name of the currently selected pre-prayer sound.
  String get preAlertLabel => preAlertTone;

  /// Kill switch for [NotificationKind]. Each kind persists independently.
  bool notifEnabled(NotificationKind kind) => switch (kind) {
        NotificationKind.prePrayer => prePrayerEnabled,
        NotificationKind.adhan => adhanSoundEnabled,
      };

  /// Name of the tone currently selected for [NotificationKind].
  String notifTone(NotificationKind kind) => switch (kind) {
        NotificationKind.prePrayer => preAlertLabel,
        NotificationKind.adhan => adhanLabel,
      };

  /// Flips the kill switch for [NotificationKind].
  AppSettings withNotifEnabled(NotificationKind kind, bool enabled) =>
      switch (kind) {
        NotificationKind.prePrayer => copyWith(prePrayerEnabled: enabled),
        NotificationKind.adhan => copyWith(adhanSoundEnabled: enabled),
      };

  AppSettings copyWith({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    int? leadMinutes,
    bool? prePrayerEnabled,
    bool? adhanSoundEnabled,
    String? adhanTone,
    String? adhanDeviceToneUri,
    String? adhanDeviceToneName,
    bool clearDeviceTone = false,
    String? preAlertTone,
    AppThemeMode? themeMode,
    LocationMode? locationMode,
    String? cityName,
    double? cityLatitude,
    double? cityLongitude,
  }) {
    return AppSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      prePrayerEnabled: prePrayerEnabled ?? this.prePrayerEnabled,
      adhanSoundEnabled: adhanSoundEnabled ?? this.adhanSoundEnabled,
      adhanTone: adhanTone ?? this.adhanTone,
      adhanDeviceToneUri:
          clearDeviceTone ? null : (adhanDeviceToneUri ?? this.adhanDeviceToneUri),
      adhanDeviceToneName:
          clearDeviceTone ? null : (adhanDeviceToneName ?? this.adhanDeviceToneName),
      preAlertTone: preAlertTone ?? this.preAlertTone,
      themeMode: themeMode ?? this.themeMode,
      locationMode: locationMode ?? this.locationMode,
      cityName: cityName ?? this.cityName,
      cityLatitude: cityLatitude ?? this.cityLatitude,
      cityLongitude: cityLongitude ?? this.cityLongitude,
    );
  }

  /// Selects a bundled tone, clearing any device-sound override.
  AppSettings withBundledTone(String name) =>
      copyWith(adhanTone: name, clearDeviceTone: true);

  /// Selects a bundled pre-prayer sound.
  AppSettings withPreAlertTone(String name) => copyWith(preAlertTone: name);

  /// Selects a device ringtone/notification sound.
  AppSettings withDeviceTone({required String name, required String uri}) =>
      copyWith(adhanDeviceToneName: name, adhanDeviceToneUri: uri);

  /// Effective coordinates: chosen city first, else resolved GPS.
  Coordinates? get effectiveCoordinates {
    if (locationMode == LocationMode.city && hasCityCoordinates) {
      return Coordinates(cityLatitude!, cityLongitude!);
    }
    return null;
  }

  CalculationParameters get parameters =>
      switch (calculationMethod) {
        CalculationMethod.muslimWorldLeague =>
          CalculationMethodParameters.muslimWorldLeague()
            ..madhab = madhab,
        CalculationMethod.northAmerica =>
          CalculationMethodParameters.northAmerica()..madhab = madhab,
        CalculationMethod.ummAlQura =>
          CalculationMethodParameters.ummAlQura()..madhab = madhab,
        CalculationMethod.egyptian =>
          CalculationMethodParameters.egyptian()..madhab = madhab,
        CalculationMethod.karachi =>
          CalculationMethodParameters.karachi()..madhab = madhab,
        CalculationMethod.tehran =>
          CalculationMethodParameters.tehran()..madhab = madhab,
        CalculationMethod.jafari =>
          CalculationMethodParameters.jafari()..madhab = madhab,
        CalculationMethod.france => CalculationMethodParameters.france()
          ..madhab = madhab,
        CalculationMethod.turkiye =>
          CalculationMethodParameters.turkiye()..madhab = madhab,
        CalculationMethod.morocco =>
          CalculationMethodParameters.morocco()..madhab = madhab,
        CalculationMethod.russia =>
          CalculationMethodParameters.russia()..madhab = madhab,
        CalculationMethod.gulfRegion =>
          CalculationMethodParameters.gulfRegion()..madhab = madhab,
        CalculationMethod.kuwait => CalculationMethodParameters.kuwait()
          ..madhab = madhab,
        CalculationMethod.qatar => CalculationMethodParameters.qatar()
          ..madhab = madhab,
        CalculationMethod.singapore =>
          CalculationMethodParameters.singapore()..madhab = madhab,
        CalculationMethod.indonesian =>
          CalculationMethodParameters.indonesian()..madhab = madhab,
        _ => CalculationMethodParameters.muslimWorldLeague()
          ..madhab = madhab,
      };
}