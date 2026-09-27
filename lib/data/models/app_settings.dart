import 'package:adhan_dart/adhan_dart.dart';

import 'package:mawaqit/data/models/notification_kind.dart';

enum AppThemeMode { system, light, dark }

/// UI language override.
///
/// `system` means "follow the device", which is what most users want and what
/// the app did before this setting existed. The other two pin the app to a
/// language regardless of the device — a real need for a bilingual user who
/// reads Arabic prayers but wants an English system, or vice versa.
///
/// No display label: see [AppLanguageL10n] in lib/l10n/enum_localization.dart.
enum AppLanguage { system, english, arabic }

extension AppLanguageCode on AppLanguage {
  /// BCP-47 code, or `null` to follow the device locale.
  ///
  /// Deliberately a `String` rather than a `Locale` so this model stays free of
  /// `dart:ui`; the widget layer turns it into a `Locale` and narrows
  /// unsupported values.
  String? get languageCode => switch (this) {
    AppLanguage.system => null,
    AppLanguage.english => 'en',
    AppLanguage.arabic => 'ar',
  };
}

/// Where prayer times derive coordinates from.
/// Where prayer times are computed from.
///
/// No display label: see [LocationModeL10n] in lib/l10n/enum_localization.dart.
enum LocationMode { autoGps, city }

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
    this.language = AppLanguage.system,
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

  /// UI language. [AppLanguage.system] defers to the device locale.
  final AppLanguage language;

  final LocationMode locationMode;
  final String? cityName;
  final double? cityLatitude;
  final double? cityLongitude;

  static const List<int> leadOptions = [0, 5, 10, 15];

  bool get hasCityCoordinates => cityLatitude != null && cityLongitude != null;

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
    AppLanguage? language,
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
      adhanDeviceToneUri: clearDeviceTone
          ? null
          : (adhanDeviceToneUri ?? this.adhanDeviceToneUri),
      adhanDeviceToneName: clearDeviceTone
          ? null
          : (adhanDeviceToneName ?? this.adhanDeviceToneName),
      preAlertTone: preAlertTone ?? this.preAlertTone,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
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

  CalculationParameters get parameters => switch (calculationMethod) {
    CalculationMethod.muslimWorldLeague =>
      CalculationMethodParameters.muslimWorldLeague()..madhab = madhab,
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
    CalculationMethod.france =>
      CalculationMethodParameters.france()..madhab = madhab,
    CalculationMethod.turkiye =>
      CalculationMethodParameters.turkiye()..madhab = madhab,
    CalculationMethod.morocco =>
      CalculationMethodParameters.morocco()..madhab = madhab,
    CalculationMethod.russia =>
      CalculationMethodParameters.russia()..madhab = madhab,
    CalculationMethod.gulfRegion =>
      CalculationMethodParameters.gulfRegion()..madhab = madhab,
    CalculationMethod.kuwait =>
      CalculationMethodParameters.kuwait()..madhab = madhab,
    CalculationMethod.qatar =>
      CalculationMethodParameters.qatar()..madhab = madhab,
    CalculationMethod.singapore =>
      CalculationMethodParameters.singapore()..madhab = madhab,
    CalculationMethod.indonesian =>
      CalculationMethodParameters.indonesian()..madhab = madhab,
    _ => CalculationMethodParameters.muslimWorldLeague()..madhab = madhab,
  };
}
