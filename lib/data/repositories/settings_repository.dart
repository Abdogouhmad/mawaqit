import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:mawaqit/core/const/pref_keys.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.appSettings);
    if (raw == null) return const AppSettings();
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.appSettings, jsonEncode(_toJson(settings)));
  }

  Map<String, dynamic> _toJson(AppSettings s) => {
    'calculationMethod': s.calculationMethod.name,
    'madhab': s.madhab.name,
    'leadMinutes': s.leadMinutes,
    'prePrayerEnabled': s.prePrayerEnabled,
    'adhanSoundEnabled': s.adhanSoundEnabled,
    'adhanTone': s.adhanTone,
    'adhanDeviceToneUri': s.adhanDeviceToneUri,
    'adhanDeviceToneName': s.adhanDeviceToneName,
    'preAlertTone': s.preAlertTone,
    'prayerSchedules': s.prayerSchedules.map(
      (id, schedule) => MapEntry(id, schedule.toJson()),
    ),
    'themeMode': s.themeMode.name,
    'language': s.language.name,
    'locationMode': s.locationMode.name,
    'cityName': s.cityName,
    'cityLatitude': s.cityLatitude,
    'cityLongitude': s.cityLongitude,
    'palette': s.palette.storageKey,
    'amoled': s.amoled,
    'reduceTransparency': s.reduceTransparency,
    'reduceMotion': s.reduceMotion,
  };

  AppSettings _fromJson(Map<String, dynamic> json) => AppSettings(
    calculationMethod: CalculationMethod.values.firstWhere(
      (e) => e.name == json['calculationMethod'],
      orElse: () => CalculationMethod.muslimWorldLeague,
    ),
    madhab: Madhab.values.firstWhere(
      (e) => e.name == json['madhab'],
      orElse: () => Madhab.shafi,
    ),
    leadMinutes:
        (json['leadMinutes'] as num?)?.toInt() ??
        const AppSettings().leadMinutes,
    prePrayerEnabled: json['prePrayerEnabled'] as bool? ?? true,
    adhanSoundEnabled: json['adhanSoundEnabled'] as bool? ?? true,
    adhanTone: json['adhanTone'] as String? ?? 'Adham Al Sharqawe',
    adhanDeviceToneUri: json['adhanDeviceToneUri'] as String?,
    adhanDeviceToneName: json['adhanDeviceToneName'] as String?,
    preAlertTone: json['preAlertTone'] as String? ?? 'Silent',
    prayerSchedules: _readSchedules(json['prayerSchedules']),
    themeMode: AppThemeMode.values.firstWhere(
      (e) => e.name == json['themeMode'],
      orElse: () => AppThemeMode.system,
    ),
    // `orElse: system` also covers a settings blob written before this field
    // existed, and a value from a future version of the app.
    language: AppLanguage.values.firstWhere(
      (e) => e.name == json['language'],
      orElse: () => AppLanguage.system,
    ),
    locationMode: LocationMode.values.firstWhere(
      (e) => e.name == json['locationMode'],
      orElse: () => LocationMode.autoGps,
    ),
    cityName: json['cityName'] as String?,
    cityLatitude: (json['cityLatitude'] as num?)?.toDouble(),
    cityLongitude: (json['cityLongitude'] as num?)?.toDouble(),
    // `fromStorageKey` falls back to the brand palette, so a blob written
    // before palettes existed still renders a coherent theme.
    palette: AppPalette.fromStorageKey(json['palette'] as String?),
    amoled: json['amoled'] as bool? ?? false,
    reduceTransparency: json['reduceTransparency'] as bool? ?? false,
    reduceMotion: json['reduceMotion'] as bool? ?? false,
  );

  /// Reads the Adhan 2.0 block defensively.
  ///
  /// A blob written before 0.21 has no such key, and a partially written one
  /// can still be recovered entry by entry: a bad prayer simply falls back to
  /// legacy behaviour instead of taking the whole settings screen down.
  Map<String, PrayerSchedule> _readSchedules(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, PrayerSchedule>{};
    for (final entry in raw.entries) {
      final id = entry.key;
      final value = entry.value;
      if (id is! String || value is! Map) continue;
      result[id] = PrayerSchedule.fromJson(Map<String, dynamic>.from(value));
    }
    return result;
  }
}
