import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/prayer_history.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/times/widgets/hijri_calendar_card.dart';
import 'package:mawaqit/features/times/widgets/insights_card.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';

/// 0.24 owns the layout contract for the two new Times cards: 360/388dp, every
/// locale and 200% text. The cards use Wrap/LayoutBuilder so long Arabic labels
/// reflow rather than overflow; this suite is what keeps them honest.
void main() {
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 9, 21, 20);
  final day = PrayerDay(
    date: DateTime(2026, 9, 21),
    prayers: [
      PrayerTime(kind: PrayerKind.fajr, time: DateTime(2026, 9, 21, 5, 10)),
      PrayerTime(kind: PrayerKind.dhuhr, time: DateTime(2026, 9, 21, 12)),
      PrayerTime(kind: PrayerKind.asr, time: DateTime(2026, 9, 21, 15, 40)),
      PrayerTime(kind: PrayerKind.maghrib, time: DateTime(2026, 9, 21, 18, 25)),
      PrayerTime(kind: PrayerKind.isha, time: DateTime(2026, 9, 21, 19, 55)),
    ],
    sunrise: DateTime(2026, 9, 21, 6, 30),
    sunset: DateTime(2026, 9, 21, 18, 25),
    solarNoon: DateTime(2026, 9, 21, 12),
    nextDayFajr: DateTime(2026, 9, 22, 5, 9),
    methodName: 'test',
  );

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('insights and Hijri cards at ${width.toInt()}dp in '
            '${locale.languageCode} at ${scale}x', (tester) async {
          tester.view.physicalSize = Size(width, 9000) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [prayerHistoryProvider.overrideWith(_StubHistory.new)],
              child: MaterialApp(
                theme: AppTheme.dark(arabic: locale.languageCode == 'ar'),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        InsightsCard(now: now, today: day),
                        HijriCalendarCard(today: now),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(InsightsCard)),
          );
          expect(find.text(l10n.insightsTitle), findsOneWidget);
          expect(find.text(l10n.calendarTitle), findsOneWidget);
        });
      }
    }
  }
}

class _StubHistory extends PrayerHistoryController {
  @override
  Future<List<PrayerHistoryEntry>> build() async => const [];
}
