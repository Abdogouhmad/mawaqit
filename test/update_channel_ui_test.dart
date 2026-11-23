import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// The channel picker is the only OTA control that changes *which signed
/// manifest* a device trusts, so it must stay visible, tappable and unclipped
/// on the narrowest phone in every supported locale — including RTL at 200%
/// text, where the bilingual labels are longest.
void main() {
  for (final width in [360.0, 388.0]) {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'channel picker at ${width.toInt()}dp in ${locale.languageCode} at ${scale}x text',
          (tester) async {
            tester.view.physicalSize = Size(width, 900) * 3;
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            final stub = _StubUpdate(const UpdateState());

            await tester.pumpWidget(
              ProviderScope(
                overrides: [updateProvider.overrideWith(() => stub)],
                child: MaterialApp(
                  theme: AppTheme.light(),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const Scaffold(body: OtaUpdateScreen()),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'overflow on the update screen at ${width.toInt()}dp in '
                  '${locale.languageCode} at ${scale}x text',
            );

            final context = tester.element(find.byType(OtaUpdateScreen));
            final l10n = AppLocalizations.of(context);
            expect(find.text(l10n.updateReleaseChannel), findsOneWidget);
            expect(find.text(l10n.updateChannelStable), findsOneWidget);
            expect(find.text(l10n.updateChannelBeta), findsOneWidget);

            // At 2x the option cards can push the install controls below the
            // fold; scroll before tapping so the test covers the real target.
            await tester.ensureVisible(find.text(l10n.updateChannelBeta));
            await tester.tap(find.text(l10n.updateChannelBeta));
            await tester.pumpAndSettle();

            expect(stub.switched, [UpdateChannel.beta]);
            expect(stub.state.channel, UpdateChannel.beta);
          },
        );
      }
    }
  }

  testWidgets('the picker cannot switch channels mid-download', (tester) async {
    final stub = _StubUpdate(
      const UpdateState(status: UpdateStatus.downloading),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [updateProvider.overrideWith(() => stub)],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: OtaUpdateScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OtaUpdateScreen)),
    );
    await tester.ensureVisible(find.text(l10n.updateChannelBeta));
    await tester.tap(find.text(l10n.updateChannelBeta));
    await tester.pumpAndSettle();

    expect(stub.switched, isEmpty);
  });
}

/// Keeps the layout test focused on the picker: no network, no shared prefs,
/// no notification plugin. The real notifier's channel switching is covered
/// separately in `update_channel_test.dart`.
class _StubUpdate extends UpdateNotifier {
  _StubUpdate(this.initialState);

  final UpdateState initialState;
  final List<UpdateChannel> switched = [];

  @override
  UpdateState build() => initialState;

  @override
  Future<void> hydrate() async {}

  @override
  Future<void> checkForUpdates({bool userInitiated = true}) async {}

  @override
  Future<void> setChannel(UpdateChannel channel) async {
    switched.add(channel);
    state = state.copyWith(channel: channel);
  }

  @override
  Future<void> setAutoCheck({required bool enabled}) async {
    state = state.copyWith(autoCheck: enabled);
  }

  @override
  Future<void> maybePromptForNotifications() async {}

  @override
  Future<void> downloadAndInstall() async {}
}
