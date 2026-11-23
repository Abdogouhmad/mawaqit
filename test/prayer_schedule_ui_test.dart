import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_schedule.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/settings/screen/prayer_schedule.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Adhan 2.0's editor is the only place a user can change one prayer without
/// touching the other four. These tests pin both halves of that promise: the
/// write goes through `SettingsController` (so the reschedule gate sees it) and
/// the weekly summary immediately tells the truth about what was saved.
void main() {
  late _RecordingSettings recorder;

  Future<AppLocalizations> pumpScreen(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    Locale locale = const Locale('en'),
    String theme = 'light',
    double textScale = 1,
    double width = 388,
  }) async {
    tester.view.physicalSize = Size(width, 12000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    recorder = _RecordingSettings(settings);
    final container = ProviderContainer(
      overrides: [settingsProvider.overrideWith(() => recorder)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: _theme(theme, locale.languageCode == 'ar'),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(body: PrayerScheduleScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(PrayerScheduleScreen)),
    );
  }

  testWidgets('disabling one prayer saves it and updates the weekly summary', (
    tester,
  ) async {
    final l10n = await pumpScreen(tester);

    expect(find.text(l10n.scheduleSummaryOff(l10n.prayerFajr)), findsNothing);
    await tester.tap(find.byKey(const Key('schedule_fajr_enabled')));
    await tester.pumpAndSettle();

    expect(recorder.saved, isNotNull);
    expect(recorder.saved!.scheduleFor(PrayerKind.fajr).enabled, isFalse);
    expect(recorder.saved!.scheduleFor(PrayerKind.dhuhr).enabled, isTrue);
    expect(find.text(l10n.scheduleSummaryOff(l10n.prayerFajr)), findsOneWidget);
  });

  testWidgets('the offset stepper clamps to fifteen minutes either way', (
    tester,
  ) async {
    await pumpScreen(tester);

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const Key('schedule_fajr_earlier')));
      await tester.pump();
    }
    expect(
      recorder.saved!.scheduleFor(PrayerKind.fajr).adhanOffsetMinutes,
      -30,
    );

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const Key('schedule_fajr_later')));
      await tester.pump();
    }
    expect(recorder.saved!.scheduleFor(PrayerKind.fajr).adhanOffsetMinutes, 30);
  });

  testWidgets('silent mode and reset stay scoped to one prayer', (
    tester,
  ) async {
    final l10n = await pumpScreen(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('schedule_fajr_mode')),
        matching: find.text(l10n.scheduleModeSilent),
      ),
    );
    await tester.pumpAndSettle();

    expect(recorder.saved!.scheduleFor(PrayerKind.fajr).mode, AdhanMode.silent);
    expect(recorder.saved!.scheduleFor(PrayerKind.isha).mode, AdhanMode.full);

    await tester.tap(find.byKey(const Key('schedule_fajr_reset')));
    await tester.pumpAndSettle();
    expect(
      recorder.saved!.scheduleFor(PrayerKind.fajr),
      const PrayerSchedule(),
    );
  });

  testWidgets('the reminder sheet stores a per-prayer lead of zero', (
    tester,
  ) async {
    final l10n = await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('schedule_fajr_reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.scheduleReminderOff));
    await tester.pumpAndSettle();

    expect(recorder.saved!.scheduleFor(PrayerKind.fajr).reminderLeadMinutes, 0);
    expect(
      recorder.saved!.scheduleFor(PrayerKind.dhuhr).reminderLeadMinutes,
      isNull,
    );
  });

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final mode in ['light', 'dark', 'amoled']) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets('schedule layout at ${width.toInt()}dp in '
              '${locale.languageCode} $mode at ${scale}x', (tester) async {
            final l10n = await pumpScreen(
              tester,
              settings: const AppSettings(
                leadMinutes: 15,
                prayerSchedules: {
                  'fajr': PrayerSchedule(
                    adhanOffsetMinutes: -30,
                    mode: AdhanMode.silent,
                  ),
                  'asr': PrayerSchedule(
                    adhanOffsetMinutes: 30,
                    reminderLeadMinutes: 30,
                  ),
                  'isha': PrayerSchedule(enabled: false),
                },
              ),
              locale: locale,
              theme: mode,
              textScale: scale,
              width: width,
            );

            expect(tester.takeException(), isNull);
            expect(find.text(l10n.scheduleWeeklyTitle), findsOneWidget);
            for (final kind in PrayerKind.five) {
              expect(find.text(kind.localizedForTest(l10n)), findsWidgets);
            }
          });
        }
      }
    }
  }
}

ThemeData _theme(String mode, bool arabic) => switch (mode) {
  'light' => AppTheme.light(arabic: arabic),
  'dark' => AppTheme.dark(arabic: arabic),
  _ => AppTheme.dark(arabic: arabic, amoled: true),
};

extension _PrayerNameForTest on PrayerKind {
  String localizedForTest(AppLocalizations l10n) => switch (this) {
    PrayerKind.fajr => l10n.prayerFajr,
    PrayerKind.dhuhr => l10n.prayerDhuhr,
    PrayerKind.asr => l10n.prayerAsr,
    PrayerKind.maghrib => l10n.prayerMaghrib,
    PrayerKind.isha => l10n.prayerIsha,
  };
}

class _RecordingSettings extends SettingsController {
  _RecordingSettings(this.initial);

  final AppSettings initial;
  AppSettings? saved;

  @override
  Future<AppSettings> build() async => initial;

  @override
  Future<void> save(AppSettings next) async {
    saved = next;
    if (ref.mounted) state = AsyncData(next);
  }
}
