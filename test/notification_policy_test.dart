import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/services/notification_service.dart';

/// These are the pure policy helpers the notification service exposes. They
/// decide whether an occurrence rings or stays a quiet card, and the persisted
/// occurrence id the native side and the mute list share — so they are worth
/// pinning down without a device.
void main() {
  group('adhanIsAudible', () {
    test('is false when the adhan alarm is switched off', () {
      const settings = AppSettings(adhanSoundEnabled: false);
      expect(NotificationService.adhanIsAudible(settings), isFalse);
    });

    test('is false for the Silent tone', () {
      const settings = AppSettings(adhanTone: ToneCatalog.silentName);
      expect(NotificationService.adhanIsAudible(settings), isFalse);
    });

    test('is false when an empty device tone overrides a Silent tone', () {
      // A device tone is only audible if it actually resolves to a URI; an
      // empty override must fall back to the (silent) bundled tone.
      const settings = AppSettings(
        adhanTone: ToneCatalog.silentName,
        adhanDeviceToneUri: '',
      );
      expect(NotificationService.adhanIsAudible(settings), isFalse);
    });

    test('is true for the default bundled recitation', () {
      const settings = AppSettings();
      expect(NotificationService.adhanIsAudible(settings), isTrue);
    });

    test('is true when a device tone URI is set, even over Silent', () {
      const settings = AppSettings(
        adhanTone: ToneCatalog.silentName,
        adhanDeviceToneUri: 'content://media/internal/audio/media/42',
        adhanDeviceToneName: 'Chime',
      );
      expect(NotificationService.adhanIsAudible(settings), isTrue);
    });

    test('a stale unknown tone name degrades to the fallback recitation', () {
      const settings = AppSettings(adhanTone: 'a-tone-that-was-removed');
      expect(NotificationService.adhanIsAudible(settings), isTrue);
    });
  });

  test('prayerIdFor is the shared persisted occurrence id', () {
    final date = DateTime(2026, 9, 21);
    expect(
      NotificationService.prayerIdFor(date, PrayerKind.maghrib),
      PrayerKeys.occurrenceId(date, PrayerKind.maghrib),
    );
    expect(
      NotificationService.prayerIdFor(date, PrayerKind.maghrib),
      '2026-09-21_maghrib',
    );
  });
}
