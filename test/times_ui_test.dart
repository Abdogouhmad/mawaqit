import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/features/times/times_screen.dart';
import 'package:mawaqit/features/times/widgets/almanac_header.dart';
import 'package:mawaqit/features/times/widgets/day_row.dart';
import 'package:mawaqit/features/times/widgets/month_shift_card.dart';
import 'package:mawaqit/features/times/widgets/prayer_labels_header.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Times-specific layout and behavior contract.
///
/// `tab_layout_test.dart` proves the tab never overflows in light mode; this
/// suite owns the 0.19 contract: three widths/locales/text scales across all
/// three themes, plus the paging and settings-change regressions that are easy
/// to break while restyling the month.
void main() {
  setUpAll(initializeDateFormatting);

  final home = _home();

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final mode in ['light', 'dark', 'amoled']) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets(
            'times lays out at ${width.toInt()}dp in ${locale.languageCode} '
            '$mode at ${scale}x',
            (tester) async {
              await _pumpTimes(
                tester,
                width: width,
                locale: locale,
                theme: _theme(mode, locale.languageCode == 'ar'),
                scale: scale,
                home: home,
              );

              expect(tester.takeException(), isNull);
              // The month lives inside a scrolled sliver. Include offstage
              // elements so the contract checks the whole month, not only the
              // three rows currently inside the viewport.
              expect(
                find.byType(AlmanacHeader, skipOffstage: false),
                findsOneWidget,
              );
              expect(
                find.byType(PrayerLabelsHeader, skipOffstage: false),
                findsOneWidget,
              );
              expect(find.byType(DayRow, skipOffstage: false), findsWidgets);
            },
          );
        }
      }
    }
  }

  testWidgets('month paging, today row and shift card expose semantics', (
    tester,
  ) async {
    await _pumpTimes(
      tester,
      width: 360,
      locale: const Locale('en'),
      theme: _theme('light', false),
      scale: 1,
      home: home,
    );

    final element = tester.element(
      find.byType(AlmanacHeader, skipOffstage: false),
    );
    final l10n = AppLocalizations.of(element);
    final nav = MaterialLocalizations.of(element);

    expect(
      find.byTooltip(nav.previousMonthTooltip, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byTooltip(nav.nextMonthTooltip, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byTooltip(l10n.timesSelectMonth, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(l10n.timesHighlightedToday),
        skipOffstage: false,
      ),
      findsWidgets,
      reason: 'today and its solar summary must be announced',
    );
    expect(find.byType(MonthShiftCard, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'RTL swaps paging glyphs and lays the month grid out right-to-left',
    (tester) async {
      final now = DateTime.now();
      final state = TimesState(
        month: DateTime(now.year, now.month + 1),
        days: const [],
        locationName: 'Test',
        isLoading: false,
      );
      final times = _StubTimes(state);

      await _pumpHeader(tester, state: state, times: times, rtl: true);

      final element = tester.element(find.byType(AlmanacHeader));
      final nav = MaterialLocalizations.of(element);
      final l10n = AppLocalizations.of(element);

      // "Back" always points against the reading direction.
      expect(
        find.descendant(
          of: find.byTooltip(nav.previousMonthTooltip),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byTooltip(nav.nextMonthTooltip),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel(l10n.timesJumpToToday));
      await tester.pump();
      expect(times.todayTaps, 1);

      await tester.tap(find.byTooltip(l10n.timesSelectMonth));
      await tester.pumpAndSettle();

      final grid = find.byType(GridView);
      expect(grid, findsOneWidget);
      expect(Directionality.of(tester.element(grid)), TextDirection.rtl);

      // January is the reading-start month: it sits on the right in Arabic.
      final monthFormat = DateFormat.MMM('ar');
      final january = find.text(monthFormat.format(DateTime(2024)));
      final december = find.text(monthFormat.format(DateTime(2024, 12)));
      expect(january, findsOneWidget);
      expect(december, findsOneWidget);
      expect(
        tester.getCenter(january).dx,
        greaterThan(tester.getCenter(december).dx),
      );
    },
  );

  testWidgets('shift cells announce their direction and magnitude', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MonthShiftCard(
            shifts: [
              TimesShift(kind: PrayerKind.fajr, minutes: 12),
              TimesShift(kind: PrayerKind.dhuhr, minutes: -8),
              TimesShift(kind: PrayerKind.asr, minutes: 0),
              TimesShift(kind: PrayerKind.maghrib, minutes: 4),
              TimesShift(kind: PrayerKind.isha, minutes: -3),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp(r'Fajr, 12m later')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Dhuhr, 8m earlier')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Asr, 0m unchanged')), findsOneWidget);
  });

  test('stepping pages one month and keeps the location loaded', () async {
    final container = _container();
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container.read(timesControllerProvider.future);
    final notifier = container.read(timesControllerProvider.notifier);
    final before = (await container.read(timesControllerProvider.future)).month;

    await notifier.step(1);
    final paged = await container.read(timesControllerProvider.future);

    expect(paged.month, DateTime(before.year, before.month + 1));
    expect(paged.hasLocation, isTrue);
    expect(paged.isLoading, isFalse);
    expect(paged.days.first.date.month, paged.month.month);
  });

  test('the controller refuses to page outside the allowed year', () async {
    final container = _container();
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container.read(timesControllerProvider.future);
    final notifier = container.read(timesControllerProvider.notifier);
    final before = (await container.read(timesControllerProvider.future)).month;

    await notifier.goToMonth(
      DateTime(before.year, before.month + TimesState.maxMonthsFromNow + 1),
    );
    final after = await container.read(timesControllerProvider.future);

    expect(after.month, before);
  });

  test(
    'a times-setting change mid-page recomputes without losing the month',
    () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container.read(timesControllerProvider.future);
      final notifier = container.read(timesControllerProvider.notifier);
      await notifier.step(1);
      final paged = await container.read(timesControllerProvider.future);

      final settings =
          container.read(settingsProvider.notifier) as _StubSettings;
      settings.emit(
        const AppSettings(calculationMethod: CalculationMethod.ummAlQura),
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final recomputed = await container.read(timesControllerProvider.future);

      expect(
        recomputed.month,
        paged.month,
        reason: 'paging must win over the recompute',
      );
      expect(recomputed.isLoading, isFalse);
      expect(recomputed.days, isNot(same(paged.days)));
      expect(
        recomputed.days.first.prayers.first.time,
        isNot(paged.days.first.prayers.first.time),
        reason: 'the new calculation method must reach the displayed month',
      );
    },
  );
}

ThemeData _theme(String mode, bool arabic) => switch (mode) {
  'light' => AppTheme.light(arabic: arabic),
  'dark' => AppTheme.dark(arabic: arabic),
  _ => AppTheme.dark(arabic: arabic, amoled: true),
};

ProviderContainer _container() => ProviderContainer(
  overrides: [
    homeControllerProvider.overrideWith(() => _StubHome(_home())),
    settingsProvider.overrideWith(_StubSettings.new),
  ],
);

Future<void> _pumpTimes(
  WidgetTester tester, {
  required double width,
  required Locale locale,
  required ThemeData theme,
  required double scale,
  required HomeState home,
}) async {
  tester.view.physicalSize = Size(width, 900) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeControllerProvider.overrideWith(() => _StubHome(home)),
        settingsProvider.overrideWith(_StubSettings.new),
      ],
      child: MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const Scaffold(body: TimesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required TimesState state,
  required _StubTimes times,
  required bool rtl,
}) async {
  final locale = rtl ? const Locale('ar') : const Locale('en');
  tester.view.physicalSize = const Size(360, 900) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [timesControllerProvider.overrideWith(() => times)],
      child: MaterialApp(
        theme: _theme('light', rtl),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AlmanacHeader(state: state)),
      ),
    ),
  );
}

HomeState _home() {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  return HomeState(
    now: now,
    locationName: 'Raleigh, NC',
    latitude: 35.775,
    longitude: -78.6336,
    isLoading: false,
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

  void emit(AppSettings settings) => state = AsyncData(settings);
}

class _StubTimes extends TimesController {
  _StubTimes(this._state);

  final TimesState _state;
  int todayTaps = 0;

  @override
  Future<TimesState> build() async => _state;

  @override
  Future<void> goToCurrentMonth() async {
    todayTaps++;
  }
}
