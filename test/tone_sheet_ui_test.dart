import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/widgets/tone_sheet.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// The tone picker already previewed in place; 0.21 adds the two explanations a
/// preview cannot give. They travel through the same ARBs as every other copy,
/// so the layout matrix doubles as a translation/overflow guard.
void main() {
  Future<AppLocalizations> pumpSheet(
    WidgetTester tester, {
    required Locale locale,
    required String theme,
    required double textScale,
    required NotificationKind kind,
    double width = 388,
  }) async {
    tester.view.physicalSize = Size(width, 12000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final recorder = _SettingsRecorder();
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
          home: Scaffold(
            body: ToneSheet(
              controller: recorder,
              initialSettings: const AppSettings(),
              kind: kind,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(ToneSheet)));
  }

  testWidgets('both tone explanations are visible for each notification kind', (
    tester,
  ) async {
    for (final kind in NotificationKind.values) {
      final l10n = await pumpSheet(
        tester,
        locale: const Locale('en'),
        theme: 'light',
        textScale: 1,
        kind: kind,
      );
      expect(find.text(l10n.toneLoudnessNote), findsOneWidget);
      expect(find.text(l10n.toneMergeNote), findsOneWidget);
      expect(find.text(l10n.toneSheetPreviewHint), findsOneWidget);
    }
  });

  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final kind in NotificationKind.values) {
        testWidgets('tone sheet layout at ${width.toInt()}dp in '
            '${locale.languageCode} at 2x (${kind.name})', (tester) async {
          final l10n = await pumpSheet(
            tester,
            locale: locale,
            theme: 'dark',
            textScale: 2,
            kind: kind,
            width: width,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(l10n.toneLoudnessNote), findsOneWidget);
          expect(find.text(l10n.toneMergeNote), findsOneWidget);
        });
      }
    }
  }
}

ThemeData _theme(String mode, bool arabic) => switch (mode) {
  'light' => AppTheme.light(arabic: arabic),
  _ => AppTheme.dark(arabic: arabic),
};

class _SettingsRecorder extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}
