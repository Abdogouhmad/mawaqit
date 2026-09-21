import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = SettingsRepository();

  test('defaults are sensible', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await repository.load();
    expect(settings.calculationMethod, CalculationMethod.muslimWorldLeague);
    expect(settings.leadMinutes, 10);
    expect(settings.adhanSoundEnabled, isTrue);
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.locationMode, LocationMode.autoGps);
  });

  test('round-trips a fully customised settings object', () async {
    final custom = const AppSettings(
      calculationMethod: CalculationMethod.ummAlQura,
      madhab: Madhab.hanafi,
      leadMinutes: 5,
      adhanSoundEnabled: false,
      adhanTone: 'Mellow Bell',
      themeMode: AppThemeMode.dark,
      locationMode: LocationMode.city,
      cityName: 'Riyadh, Saudi Arabia',
      cityLatitude: 24.7136,
      cityLongitude: 46.6753,
    );
    SharedPreferences.setMockInitialValues({});
    await repository.save(custom);
    final loaded = await repository.load();

    expect(loaded.calculationMethod, CalculationMethod.ummAlQura);
    expect(loaded.madhab, Madhab.hanafi);
    expect(loaded.leadMinutes, 5);
    expect(loaded.adhanSoundEnabled, isFalse);
    expect(loaded.adhanTone, 'Mellow Bell');
    expect(loaded.themeMode, AppThemeMode.dark);
    expect(loaded.locationMode, LocationMode.city);
    expect(loaded.cityName, 'Riyadh, Saudi Arabia');
    expect(loaded.cityLatitude, 24.7136);
    expect(loaded.cityLongitude, 46.6753);
  });

  test('chosen city wins over GPS in effective coordinates', () {
    const auto = AppSettings();
    const city = AppSettings(
      locationMode: LocationMode.city,
      cityName: 'London, United Kingdom',
      cityLatitude: 51.5074,
      cityLongitude: -0.1278,
    );

    expect(auto.effectiveCoordinates, isNull);
    expect(city.effectiveCoordinates!.latitude, 51.5074);
    expect(city.effectiveCoordinates!.longitude, -0.1278);
  });

  test('device ringtone overrides bundled tone and round-trips', () async {
    const custom = AppSettings(
      adhanTone: 'Mellow Bell',
      adhanDeviceToneName: 'Over the Horizon',
      adhanDeviceToneUri: 'content://media/internal/audio/media/42',
    );
    SharedPreferences.setMockInitialValues({});
    await repository.save(custom);
    final loaded = await repository.load();

    expect(loaded.usesDeviceTone, isTrue);
    expect(loaded.adhanLabel, 'Over the Horizon');
    expect(loaded.adhanDeviceToneUri, 'content://media/internal/audio/media/42');

    final bundled = loaded.withBundledTone('Zen Bow');
    expect(bundled.usesDeviceTone, isFalse);
    expect(bundled.adhanDeviceToneUri, isNull);
    expect(bundled.adhanTone, 'Zen Bow');
    expect(bundled.adhanLabel, 'Zen Bow');

    final device = bundled.withDeviceTone(
      name: 'Chime',
      uri: 'content://media/internal/audio/media/7',
    );
    expect(device.usesDeviceTone, isTrue);
    expect(device.adhanLabel, 'Chime');
  });
}