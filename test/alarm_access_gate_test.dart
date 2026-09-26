import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/services/alarm_access_prompt.dart';
import 'package:mawaqit/features/home/widgets/alarm_access_gate.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mawaqit/native');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Native status map with everything granted except the pieces under test.
  Map<String, Object?> status({required bool battery}) => {
    'notifications': true,
    'exactAlarms': true,
    'fullScreenIntent': true,
    'policyAccess': true,
    'batteryUnrestricted': battery,
  };

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Mawaqit',
      packageName: 'com.mawaqit.mawaqit',
      version: '0.8.5',
      buildNumber: '85',
      buildSignature: '',
    );
    AppInfo.init();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AlarmAccessGate())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks once on a fresh install and offers the exemption', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          call.method == 'alarmAccessStatus' ? status(battery: false) : true,
    );

    await pumpGate(tester);

    expect(find.text('Keep the adhan on time'), findsOneWidget);
    expect(
      find.textContaining('freezes apps while the screen is locked'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('battery-exemption-allow')), findsOneWidget);
    expect(find.byKey(const Key('battery-exemption-later')), findsOneWidget);

    // Asking is what marks the build, so a relaunch (or a rotation) is quiet.
    expect(
      await AlarmAccessPromptStore().lastPromptedBuild(),
      AppInfo.buildNumber,
    );

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('"Allow" opens the system exemption screen', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final requested = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'alarmAccessStatus') return status(battery: false);
      if (call.method == 'requestAlarmAccess') {
        requested.add((call.arguments as Map)['key'] as String);
        return true;
      }
      return null;
    });

    await pumpGate(tester);
    await tester.tap(find.byKey(const Key('battery-exemption-allow')));
    await tester.pumpAndSettle();

    expect(requested, ['batteryUnrestricted']);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('"Not now" dismisses it without opening anything', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final requested = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'alarmAccessStatus') return status(battery: false);
      if (call.method == 'requestAlarmAccess') {
        requested.add((call.arguments as Map)['key'] as String);
        return true;
      }
      return null;
    });

    await pumpGate(tester);
    await tester.tap(find.byKey(const Key('battery-exemption-later')));
    await tester.pumpAndSettle();

    expect(find.text('Keep the adhan on time'), findsNothing);
    expect(requested, isEmpty);
    // Still recorded for this build, so it cannot come back on every launch.
    expect(
      await AlarmAccessPromptStore().lastPromptedBuild(),
      AppInfo.buildNumber,
    );

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('says nothing once the exemption is granted', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          call.method == 'alarmAccessStatus' ? status(battery: true) : true,
    );

    await pumpGate(tester);

    expect(find.text('Keep the adhan on time'), findsNothing);
    expect(await AlarmAccessPromptStore().lastPromptedBuild(), isNull);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('says nothing off Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          call.method == 'alarmAccessStatus' ? status(battery: false) : true,
    );

    await pumpGate(tester);

    expect(find.text('Keep the adhan on time'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });
}
