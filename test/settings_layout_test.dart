import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/settings_screen.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// 0.20 makes Settings the single home for every preference, including the
/// stable/beta choice. At 2x text in RTL the bilingual channel descriptions are
/// the longest strings in the app, so they double as the layout canary.
void main() {
  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final mode in ['light', 'dark', 'amoled']) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets(
            'settings at ${width.toInt()}dp in ${locale.languageCode} '
            '$mode at ${scale}x',
            (tester) async {
              // A tall viewport builds the whole ListView; the width and text
              // scale are the axes under test, and this keeps every preference
              // mounted so a missing row cannot hide below the fold.
              tester.view.physicalSize = Size(width, 12000) * 3;
              tester.view.devicePixelRatio = 3;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    settingsProvider.overrideWith(_StubSettings.new),
                    updateProvider.overrideWith(_StubUpdate.new),
                  ],
                  child: MaterialApp(
                    theme: _theme(mode, locale.languageCode == 'ar'),
                    locale: locale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                    home: const Scaffold(body: SettingsScreen()),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
              final l10n = AppLocalizations.of(
                tester.element(find.byType(SettingsScreen)),
              );
              expect(find.text(l10n.settingsTitle), findsOneWidget);
              expect(
                find.text(l10n.settingsSectionPermissions.toUpperCase()),
                findsOneWidget,
              );
              expect(
                find.text(l10n.settingsSectionAbout.toUpperCase()),
                findsOneWidget,
              );
              expect(find.text(l10n.updateReleaseChannel), findsOneWidget);
              expect(find.text(l10n.updateChannelStable), findsOneWidget);
              expect(find.text(l10n.updateChannelBeta), findsOneWidget);
            },
          );
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

class _StubSettings extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}

class _StubUpdate extends UpdateNotifier {
  @override
  UpdateState build() => const UpdateState();
}
