import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/models/alarm_access.dart';
import 'package:mawaqit/data/services/alarm_access_prompt.dart';

void main() {
  const missing = AlarmAccess(battery: false);
  const granted = AlarmAccess();

  group('shouldAskForBatteryExemption', () {
    test('asks on a fresh install (nothing prompted yet)', () {
      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: 85,
          lastPromptedBuild: null,
        ),
        isTrue,
      );
    });

    test('asks again after an update', () {
      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: 86,
          lastPromptedBuild: 85,
        ),
        isTrue,
      );
    });

    test('never asks twice in the same build', () {
      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: 86,
          lastPromptedBuild: 86,
        ),
        isFalse,
      );
    });

    test('stays quiet once the exemption is granted', () {
      expect(
        shouldAskForBatteryExemption(
          access: granted,
          currentBuild: 86,
          lastPromptedBuild: 85,
        ),
        isFalse,
      );
    });

    test('stays quiet when the build is unknown', () {
      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: null,
          lastPromptedBuild: null,
        ),
        isFalse,
      );
    });
  });

  group('AlarmAccessPromptStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('remembers the build it asked for', () async {
      final store = AlarmAccessPromptStore();
      expect(await store.lastPromptedBuild(), isNull);

      await store.markPromptedBuild(85);
      expect(await store.lastPromptedBuild(), 85);
    });

    test('a dismissed ask is remembered for that build only', () async {
      SharedPreferences.setMockInitialValues({
        AlarmAccessPromptStore.kLastPromptedBuildKey: 85,
      });
      final store = AlarmAccessPromptStore();

      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: 85,
          lastPromptedBuild: await store.lastPromptedBuild(),
        ),
        isFalse,
      );
      expect(
        shouldAskForBatteryExemption(
          access: missing,
          currentBuild: 86,
          lastPromptedBuild: await store.lastPromptedBuild(),
        ),
        isTrue,
      );
    });
  });
}
