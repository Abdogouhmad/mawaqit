import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/const/prayer_keys.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_schedule.dart';
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

  group('Adhan 2.0 per-prayer policy', () {
    test('a disabled prayer never takes the audible path', () {
      final settings = const AppSettings().withPrayerSchedule(
        PrayerKind.fajr,
        const PrayerSchedule(enabled: false),
      );
      expect(
        NotificationService.adhanIsEnabled(settings, PrayerKind.fajr),
        isFalse,
      );
      expect(
        NotificationService.adhanIsAudible(settings, kind: PrayerKind.fajr),
        isFalse,
      );
      expect(
        NotificationService.adhanIsEnabled(settings, PrayerKind.dhuhr),
        isTrue,
      );
    });

    test('silent mode keeps the card but drops the audible path', () {
      final settings = const AppSettings().withPrayerSchedule(
        PrayerKind.asr,
        const PrayerSchedule(mode: AdhanMode.silent),
      );
      expect(
        NotificationService.adhanIsAudible(settings, kind: PrayerKind.asr),
        isFalse,
      );
      expect(
        NotificationService.adhanIsAudible(settings),
        isTrue,
        reason: 'the global switch and other prayers are unaffected',
      );
    });

    test(
      'the global adhan switch still wins over a full per-prayer choice',
      () {
        final settings = const AppSettings(adhanSoundEnabled: false)
            .withPrayerSchedule(PrayerKind.isha, const PrayerSchedule());
        expect(
          NotificationService.adhanIsAudible(settings, kind: PrayerKind.isha),
          isFalse,
        );
      },
    );

    test('the offset moves the ring time exactly once', () {
      final prayerTime = DateTime(2026, 11, 23, 5, 12);
      expect(
        NotificationService.adhanTime(
          prayerTime,
          const PrayerSchedule(adhanOffsetMinutes: -5),
        ),
        DateTime(2026, 11, 23, 5, 7),
      );
      expect(
        NotificationService.adhanTime(
          prayerTime,
          const PrayerSchedule(adhanOffsetMinutes: 10),
        ),
        DateTime(2026, 11, 23, 5, 22),
      );
    });

    test('an untouched prayer inherits the global lead time', () {
      const settings = AppSettings(leadMinutes: 15);
      for (final kind in PrayerKind.five) {
        expect(NotificationService.reminderLeadMinutes(settings, kind), 15);
      }
    });

    test('a per-prayer lead overrides the global one, including zero', () {
      final settings = const AppSettings(leadMinutes: 15).withPrayerSchedule(
        PrayerKind.maghrib,
        const PrayerSchedule(reminderLeadMinutes: 0),
      );
      expect(
        NotificationService.reminderLeadMinutes(settings, PrayerKind.maghrib),
        0,
      );
      expect(
        NotificationService.reminderIsEnabled(settings, PrayerKind.maghrib),
        isFalse,
      );
      expect(
        NotificationService.reminderIsEnabled(settings, PrayerKind.fajr),
        isTrue,
      );
    });

    test('a disabled prayer loses both its adhan and its reminder', () {
      final settings = const AppSettings().withPrayerSchedule(
        PrayerKind.dhuhr,
        const PrayerSchedule(enabled: false),
      );
      expect(
        NotificationService.adhanIsEnabled(settings, PrayerKind.dhuhr),
        isFalse,
      );
      expect(
        NotificationService.reminderIsEnabled(settings, PrayerKind.dhuhr),
        isFalse,
      );
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
