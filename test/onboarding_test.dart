import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/const/pref_keys.dart';
import 'package:mawaqit/core/navigation/app_router.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/onboarding/onboarding_gate.dart';
import 'package:mawaqit/features/onboarding/onboarding_screen.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first-run flow replaces a permission gate with an explanation. These
/// tests pin the two contracts that are easy to lose: the gate never flashes a
/// tab before onboarding, and leaving halfway through resumes on the same page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('mawaqit/native');
  final requests = <String>[];

  Map<String, Object?> status({bool exactAlarms = true}) => <String, Object?>{
    'notifications': true,
    'exactAlarms': exactAlarms,
    'fullScreenIntent': true,
    'overlay': true,
    'policyAccess': true,
    'batteryUnrestricted': true,
  };

  setUp(() {
    requests.clear();
    SharedPreferences.setMockInitialValues({});
    OnboardingGate.instance.resetForTests();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'alarmAccessStatus') return status();
      if (call.method == 'requestAlarmAccess') {
        requests.add(call.arguments['key'] as String);
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    OnboardingGate.instance.resetForTests();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('the gate loads, resumes and persists completion', () async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.onboardingComplete: false,
      PrefKeys.onboardingStep: 2,
    });
    final gate = OnboardingGate.instance;
    await gate.load();
    expect(gate.isComplete, isFalse);
    expect(gate.step, 2);

    await gate.rememberStep(3);
    final reread = await SharedPreferences.getInstance();
    expect(reread.getInt(PrefKeys.onboardingStep), 3);

    await gate.complete(keepStep: true);
    expect(gate.isComplete, isTrue);
    expect(gate.step, 3);

    await gate.complete();
    expect(gate.step, 0);
    expect(
      (await SharedPreferences.getInstance()).getInt(PrefKeys.onboardingStep),
      isNull,
    );
  });

  testWidgets('first run opens on the walkthrough, not a tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingGate.instance.load();

    await pumpRouter(tester, initialLocation: '/times');

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(OnboardingGate.instance.pendingTarget, '/times');
  });

  testWidgets('an interrupted run resumes on its saved page', (tester) async {
    SharedPreferences.setMockInitialValues({PrefKeys.onboardingStep: 1});
    await OnboardingGate.instance.load();

    await pumpRouter(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );
    expect(find.text(l10n.onboardingAlertsTitle), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingTakeoverTitle), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PrefKeys.onboardingStep), 2);
  });

  testWidgets('skip is skippable, resumable and returns the deep link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingGate.instance.load();

    await pumpRouter(tester, initialLocation: '/times');
    final context = tester.element(find.byType(OnboardingScreen));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.byTooltip(l10n.onboardingSkip));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(OnboardingGate.instance.isComplete, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        PrefKeys.onboardingComplete,
      ),
      isTrue,
    );
  });

  testWidgets('permission rows show live state and open a fix screen', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'alarmAccessStatus') {
        return status(exactAlarms: false);
      }
      if (call.method == 'requestAlarmAccess') {
        requests.add(call.arguments['key'] as String);
        return true;
      }
      return null;
    });
    SharedPreferences.setMockInitialValues({PrefKeys.onboardingStep: 1});
    await OnboardingGate.instance.load();

    await pumpRouter(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );

    expect(find.text(l10n.accessFix), findsOneWidget);
    expect(find.text(l10n.accessAllowed), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.accessFix));
    await tester.tap(find.text(l10n.accessFix));
    await tester.pumpAndSettle();

    expect(requests, ['exactAlarms']);

    // The framework checks foundation debug vars before tearDown runs.
    debugDefaultTargetPlatformOverride = null;
  });

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 1.5, 2.0]) {
        for (final step in List<int>.generate(
          OnboardingScreen.pageCount,
          (index) => index,
        )) {
          testWidgets('walkthrough page $step at ${width.toInt()}dp in '
              '${locale.languageCode} at ${scale}x', (tester) async {
            tester.view.physicalSize = Size(width, 900) * 3;
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);
            // Permission cards are Android-only; force that platform so the
            // widest page is the one under test, then clear it before the
            // framework's post-test invariant check.
            if (step == 1 || step == 2) {
              debugDefaultTargetPlatformOverride = TargetPlatform.android;
            }
            SharedPreferences.setMockInitialValues({
              PrefKeys.onboardingStep: step,
            });
            await OnboardingGate.instance.load();

            await pumpRouter(tester, locale: locale, scale: scale);

            expect(tester.takeException(), isNull);
            expect(find.byType(OnboardingScreen), findsOneWidget);
            debugDefaultTargetPlatformOverride = null;
          });
        }
      }
    }
  }
}

Future<void> pumpRouter(
  WidgetTester tester, {
  String initialLocation = '/',
  Locale locale = const Locale('en'),
  double scale = 1,
}) async {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  final home = HomeState(
    now: now,
    locationName: 'Raleigh, NC',
    latitude: 35.775,
    longitude: -78.6336,
    day: PrayerDay(
      date: date,
      prayers: PrayerKind.five
          .map(
            (kind) => PrayerTime(
              kind: kind,
              time: date.add(
                Duration(hours: 5 + PrayerKind.five.indexOf(kind)),
              ),
            ),
          )
          .toList(),
      sunrise: date.add(const Duration(hours: 6)),
      sunset: date.add(const Duration(hours: 18)),
      solarNoon: date.add(const Duration(hours: 12)),
      nextDayFajr: date.add(const Duration(days: 1, hours: 5)),
      methodName: 'Test',
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeControllerProvider.overrideWith(() => _StubHome(home)),
        settingsProvider.overrideWith(_StubSettings.new),
      ],
      child: MaterialApp.router(
        routerConfig: createRouter(initialLocation: initialLocation),
        theme: AppTheme.light(arabic: locale.languageCode == 'ar'),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StubHome extends HomeController {
  _StubHome(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;
}

class _StubSettings extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}
