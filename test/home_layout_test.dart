import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/home/home_screen.dart';
import 'package:mawaqit/features/home/widgets/countdown_hero.dart';
import 'package:mawaqit/features/home/widgets/prayer_schedule_tile.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home-specific layout and rebuild contract.
///
/// `tab_layout_test.dart` sweeps every tab at 1x, but its stub has no next
/// prayer, so the hero never renders. This suite gives Home a real current/next
/// pair and sweeps the axes the new hero and prayer timeline can actually break
/// on: width, locale, text scale and the three theme modes (light, dark, AMOLED).
void main() {
  final home = _home();

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final mode in ['light', 'dark', 'amoled']) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets(
            'home lays out at ${width.toInt()}dp in ${locale.languageCode} '
            '$mode at ${scale}x',
            (tester) async {
              await _pumpHome(
                tester,
                width: width,
                locale: locale,
                theme: _theme(mode, locale.languageCode == 'ar'),
                scale: scale,
                home: home,
              );

              expect(tester.takeException(), isNull);
              expect(find.byType(CountdownHero), findsOneWidget);
              expect(find.byType(PrayerScheduleTile), findsNWidgets(5));
            },
          );
        }
      }
    }
  }

  testWidgets('hero, actions and mute control expose semantics', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      width: 360,
      locale: const Locale('en'),
      theme: _theme('light', false),
      scale: 1,
      home: home,
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

    expect(
      find.bySemanticsLabel(RegExp(l10n.homeNextPrayer)),
      findsWidgets,
      reason: 'next-prayer hero must be announced',
    );
    expect(
      find.bySemanticsLabel(RegExp('Dhuhr')),
      findsWidgets,
      reason: 'the next prayer name must be announced',
    );
    // The app bar's title and action share one semantics node, so match the
    // label as a substring and assert the tooltip separately to pin the
    // individual button.
    expect(
      find.bySemanticsLabel(RegExp(l10n.navTimes)),
      findsWidgets,
      reason: 'the Times action must be announced in the app bar',
    );
    expect(find.byTooltip(l10n.navTimes), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.navSettings),
      findsNothing,
      reason: 'Settings lives in the bottom navigation, not the Home app bar',
    );
    expect(
      find.bySemanticsLabel(RegExp('Dhuhr adhan|adhan')),
      findsWidgets,
      reason: 'each mute control is its own toggle',
    );
  });

  testWidgets('a clock tick does not rebuild the Home body', (tester) async {
    final builds = ValueNotifier<int>(0);
    final ticks = ValueNotifier<int>(0);

    await _pumpHome(
      tester,
      width: 388,
      locale: const Locale('en'),
      theme: _theme('light', false),
      scale: 1,
      home: home,
      child: Stack(children: [_CountingHomeScreen(builds), _ClockProbe(ticks)]),
    );

    final initialBuilds = builds.value;
    final initialTicks = ticks.value;

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(ticks.value, greaterThan(initialTicks), reason: 'clock must tick');
    expect(
      builds.value,
      initialBuilds,
      reason: 'only the countdown and sunset leaves may rebuild on a tick',
    );
  });
}

ThemeData _theme(String mode, bool arabic) => switch (mode) {
  'light' => AppTheme.light(arabic: arabic),
  'dark' => AppTheme.dark(arabic: arabic),
  _ => AppTheme.dark(arabic: arabic, amoled: true),
};

Future<void> _pumpHome(
  WidgetTester tester, {
  required double width,
  required Locale locale,
  required ThemeData theme,
  required double scale,
  required HomeState home,
  Widget? child,
}) async {
  tester.view.physicalSize = Size(width, 900) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeControllerProvider.overrideWith(() => _StubHome(home))],
      child: MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: widget!,
        ),
        home: child ?? const HomeScreen(),
      ),
    ),
  );
  // The live pulse and clock are intentionally continuous, so pumpAndSettle()
  // can never finish here. Two bounded pumps are enough for the async
  // HomeController future and the first frame after it resolves.
  await tester.pump();
  await tester.pump();
}

HomeState _home() {
  final now = DateTime(2026, 11, 22, 10, 30);
  final date = DateTime(now.year, now.month, now.day);
  final prayers = [
    PrayerTime(kind: PrayerKind.fajr, time: date.add(const Duration(hours: 5))),
    PrayerTime(
      kind: PrayerKind.dhuhr,
      time: date.add(const Duration(hours: 12)),
    ),
    PrayerTime(kind: PrayerKind.asr, time: date.add(const Duration(hours: 15))),
    PrayerTime(
      kind: PrayerKind.maghrib,
      time: date.add(const Duration(hours: 18)),
    ),
    PrayerTime(
      kind: PrayerKind.isha,
      time: date.add(const Duration(hours: 20)),
    ),
  ];

  return HomeState(
    now: now,
    day: PrayerDay(
      date: date,
      prayers: prayers,
      sunrise: date.add(const Duration(hours: 6)),
      sunset: date.add(const Duration(hours: 18)),
      solarNoon: date.add(const Duration(hours: 12, minutes: 30)),
      nextDayFajr: date.add(const Duration(days: 1, hours: 5)),
      methodName: 'North America',
    ),
    locationName: 'Raleigh, North Carolina',
    latitude: 35.775,
    longitude: -78.6336,
    methodLabel: 'North America',
    currentPrayer: prayers.first,
    nextPrayer: prayers[1],
    isLoading: false,
  );
}

class _StubHome extends HomeController {
  _StubHome(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;
}

class _CountingHomeScreen extends HomeScreen {
  // A non-const probe is unavoidable: it has to capture the build counter.
  // ignore: prefer_const_constructors_in_immutables
  _CountingHomeScreen(this.counter);

  final ValueNotifier<int> counter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    counter.value++;
    return super.build(context, ref);
  }
}

class _ClockProbe extends ConsumerWidget {
  const _ClockProbe(this.ticks);

  final ValueNotifier<int> ticks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeClockProvider);
    ticks.value++;
    return const SizedBox.shrink();
  }
}
