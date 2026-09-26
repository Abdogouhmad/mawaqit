import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/features/settings/widgets/alarm_access_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AlarmAccessSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('mawaqit/native'),
      (call) async => call.method == 'alarmAccessStatus'
          ? <String, Object?>{
              'notifications': true,
              'exactAlarms': true,
              'fullScreenIntent': true,
              'overlay': true,
              'policyAccess': true,
              'batteryUnrestricted': true,
            }
          : null,
    );
  });

  // The override must be dropped inside the test body: the framework asserts on
  // it as soon as the body returns.
  void usePlatform(TargetPlatform? platform) {
    debugDefaultTargetPlatformOverride = platform;
  }

  testWidgets('every access is listed with its grant state', (tester) async {
    usePlatform(TargetPlatform.android);
    messenger.setMockMethodCallHandler(
      const MethodChannel('mawaqit/native'),
      (call) async => call.method == 'alarmAccessStatus'
          ? <String, Object?>{
              'notifications': true,
              'exactAlarms': false,
              'fullScreenIntent': true,
              'overlay': true,
              'policyAccess': false,
              'batteryUnrestricted': true,
            }
          : null,
    );

    await pump(tester);

    expect(find.text('ALARM RELIABILITY'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Alarms & reminders'), findsOneWidget);
    expect(find.text('Full-screen notifications'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Do Not Disturb access'), findsOneWidget);
    expect(find.text('Unrestricted battery'), findsOneWidget);

    // notifications, full-screen, "display over other apps" and battery are
    // granted; exact alarms and Do Not Disturb access are not.
    expect(find.text('Allowed'), findsNWidgets(4));
    expect(find.text('Fix'), findsNWidgets(2));
    expect(find.textContaining('2 of 6 accesses are off'), findsOneWidget);

    usePlatform(null);
  });

  testWidgets('a fully granted device says so and offers nothing to fix', (
    tester,
  ) async {
    usePlatform(TargetPlatform.android);

    await pump(tester);

    expect(find.text('All alarm accesses granted'), findsOneWidget);
    expect(find.text('Fix'), findsNothing);
    expect(find.text('Allowed'), findsNWidgets(6));

    usePlatform(null);
  });

  testWidgets('the block is absent off Android', (tester) async {
    usePlatform(TargetPlatform.linux);

    await pump(tester);

    expect(find.byType(AlarmAccessSection), findsOneWidget);
    expect(find.text('ALARM RELIABILITY'), findsNothing);

    usePlatform(null);
  });
}
