import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/models/app_settings.dart';

class SettingsRepository {
  static const _key = 'app_settings_v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(settings)));
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
        'themeMode': s.themeMode.name,
        'locationMode': s.locationMode.name,
        'cityName': s.cityName,
        'cityLatitude': s.cityLatitude,
        'cityLongitude': s.cityLongitude,
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
            (json['leadMinutes'] as num?)?.toInt() ?? AppSettings.leadOptions[1],
        prePrayerEnabled: json['prePrayerEnabled'] as bool? ?? true,
        adhanSoundEnabled: json['adhanSoundEnabled'] as bool? ?? true,
        adhanTone: json['adhanTone'] as String? ?? 'Adham Al Sharqawe',
        adhanDeviceToneUri: json['adhanDeviceToneUri'] as String?,
        adhanDeviceToneName: json['adhanDeviceToneName'] as String?,
        preAlertTone: json['preAlertTone'] as String? ?? 'Silent',
        themeMode: AppThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        locationMode: LocationMode.values.firstWhere(
          (e) => e.name == json['locationMode'],
          orElse: () => LocationMode.autoGps,
        ),
        cityName: json['cityName'] as String?,
        cityLatitude: (json['cityLatitude'] as num?)?.toDouble(),
        cityLongitude: (json['cityLongitude'] as num?)?.toDouble(),
      );
}