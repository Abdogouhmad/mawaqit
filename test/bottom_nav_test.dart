import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/navigation/app_router.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bottom chrome is now a standard Material 3 [NavigationBar] in the
/// `Scaffold.bottomNavigationBar` slot — not a detached floating pill. These
/// tests pin the Google-style behaviour: one labelled destination per tab,
/// tappable, exposed to assistive tech, and wired to the real router.
Widget bar({ValueChanged<int>? onSelected}) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: const SizedBox.shrink(),
    bottomNavigationBar: Builder(
      builder: (context) => AppNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: onSelected ?? (_) {},
        destinations: [
          for (final path in AppRoutes.tabs)
            AppRoutes.destinationFor(context, path),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('renders one labelled destination per tab', (tester) async {
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Times', 'Settings']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('reports the tapped destination index', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(bar(onSelected: selected.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('labels every destination for assistive tech', (tester) async {
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();

    // Material puts the semantic "Tab 1 of 3" label on the node and exposes the
    // human label as a tooltip, so both must be present for a screen reader to
    // announce a destination properly.
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Times'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Tab 1 of 3')), findsOneWidget);
  });

  testWidgets('navigates to the selected tab through the real router', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = createRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeControllerProvider.overrideWith(_StubHome.new)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    await tester.tap(find.text('Times'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.times);
  });
}

/// Keeps the real Home screen out of the test: the production controller starts
/// a one-second clock ticker, which never lets `pumpAndSettle` finish.
class _StubHome extends HomeController {
  @override
  Future<HomeState> build() async => HomeState(now: DateTime(2026, 11, 22));
}
