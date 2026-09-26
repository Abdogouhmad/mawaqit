import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/alarm_access.dart';

void main() {
  group('AlarmAccess.fromMap', () {
    test('reads every grant the native status reports', () {
      final access = AlarmAccess.fromMap({
        'notifications': true,
        'exactAlarms': false,
        'fullScreenIntent': true,
        'overlay': false,
        'policyAccess': false,
        'batteryUnrestricted': false,
      });

      expect(access.notifications, isTrue);
      expect(access.exactAlarms, isFalse);
      expect(access.fullScreenIntent, isTrue);
      expect(access.overlay, isFalse);
      expect(access.policyAccess, isFalse);
      expect(access.battery, isFalse);
    });

    test('treats a missing key as granted, never inventing a warning', () {
      // An older native side (or a release without the access) reports fewer
      // keys; the user must not be sent to a screen that does not exist.
      final access = AlarmAccess.fromMap({'exactAlarms': false});

      expect(access.exactAlarms, isFalse);
      expect(access.missing, [AlarmPermission.exactAlarms]);
    });

    test('a null status is fully permitted (no Android host)', () {
      expect(AlarmAccess.fromMap(null), AlarmAccess.all);
      expect(AlarmAccess.all.missing, isEmpty);
    });

    test('ignores non-boolean values instead of crashing', () {
      final access = AlarmAccess.fromMap({'notifications': 'granted'});
      expect(access.notifications, isTrue);
    });
  });

  group('AlarmAccess', () {
    test('lists the missing grants in enum order', () {
      const access = AlarmAccess(
        notifications: false,
        exactAlarms: true,
        fullScreenIntent: false,
        overlay: false,
        policyAccess: false,
        battery: true,
      );

      expect(access.missing, [
        AlarmPermission.notifications,
        AlarmPermission.fullScreenIntent,
        AlarmPermission.overlay,
        AlarmPermission.policyAccess,
      ]);
    });

    test('canRingOnTime needs notifications, exact alarms and full-screen', () {
      expect(AlarmAccess.all.canRingOnTime, isTrue);
      expect(
        const AlarmAccess(exactAlarms: false).canRingOnTime,
        isFalse,
        reason: 'inexact alarms are batched into a maintenance window',
      );
      expect(
        const AlarmAccess(fullScreenIntent: false).canRingOnTime,
        isFalse,
        reason: 'the alarm cannot take over the lockscreen',
      );
      expect(
        const AlarmAccess(policyAccess: false).canRingOnTime,
        isTrue,
        reason: 'a silenced phone is a separate concern from timing',
      );
      expect(
        const AlarmAccess(overlay: false).canRingOnTime,
        isTrue,
        reason: 'the lockscreen takeover still works without it',
      );
    });

    test('canForceAdhan needs both the silent-mode and the screen access', () {
      expect(AlarmAccess.all.canForceAdhan, isTrue);
      expect(const AlarmAccess(policyAccess: false).canForceAdhan, isFalse);
      expect(
        const AlarmAccess(overlay: false).canForceAdhan,
        isFalse,
        reason: 'a phone in use is not reachable without the overlay access',
      );
    });

    test('canAlwaysTakeOver separates the locked and in-use screens', () {
      expect(AlarmAccess.all.canAlwaysTakeOver, isTrue);
      expect(
        const AlarmAccess(fullScreenIntent: false).canAlwaysTakeOver,
        isFalse,
      );
      expect(
        const AlarmAccess(overlay: false).canAlwaysTakeOver,
        isFalse,
        reason: 'an unlocked screen has no other route to the presenter',
      );
      expect(
        const AlarmAccess(exactAlarms: false).canAlwaysTakeOver,
        isTrue,
        reason: 'taking the screen is independent of firing on time',
      );
    });

    test('copyWith changes only what it is given', () {
      const access = AlarmAccess();
      final fixed = access.copyWith(exactAlarms: false, battery: false);

      expect(fixed.exactAlarms, isFalse);
      expect(fixed.battery, isFalse);
      expect(fixed.notifications, isTrue);
      expect(access.exactAlarms, isTrue, reason: 'the original is untouched');
    });

    test('granted() mirrors the individual flags', () {
      const access = AlarmAccess(policyAccess: false);
      expect(access.granted(AlarmPermission.policyAccess), isFalse);
      expect(access.granted(AlarmPermission.battery), isTrue);
    });

    test('equality is by value so a reschedule can detect a real change', () {
      expect(const AlarmAccess(), AlarmAccess.all);
      expect(
        const AlarmAccess().copyWith(exactAlarms: false),
        isNot(const AlarmAccess()),
      );
    });
  });
}
