import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/ui/widgets/app_chrome.dart';
import 'package:mawaqit/features/home/home_screen.dart';
import 'package:mawaqit/features/settings/settings_screen.dart';
import 'package:mawaqit/features/times/times_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Route paths for the tabs.
///
/// A flat scheme with no nesting, so the tab *is* the path — `go('/times')` is
/// the whole navigation, and back-from-a-tab falls out of `GoRouter`'s own stack
/// rather than being hand-maintained.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String times = '/times';
  static const String settings = '/settings';

  /// Tab order, start to end. Material's [NavigationBar] lays its destinations
  /// out directionally, so this logical order is correct in both LTR and RTL.
  static const List<String> tabs = [home, times, settings];

  static String labelFor(BuildContext context, String path) {
    final l10n = AppLocalizations.of(context);
    return switch (path) {
      home => l10n.navHome,
      times => l10n.navTimes,
      settings => l10n.navSettings,
      _ => l10n.navHome,
    };
  }

  /// Material 3 destination for one tab, resolved at build time so the label
  /// follows the user's current language.
  static NavigationDestination destinationFor(
    BuildContext context,
    String path,
  ) => NavigationDestination(
    icon: switch (path) {
      times => const Icon(Icons.calendar_month_outlined),
      settings => const Icon(Icons.settings_outlined),
      _ => const Icon(Icons.home_outlined),
    },
    selectedIcon: switch (path) {
      times => const Icon(Icons.calendar_month_rounded),
      settings => const Icon(Icons.settings_rounded),
      _ => const Icon(Icons.home_rounded),
    },
    label: labelFor(context, path),
    tooltip: labelFor(context, path),
  );
}

/// The tabbed shell: a standard Material 3 [Scaffold] whose
/// [Scaffold.bottomNavigationBar] is a Google-style [NavigationBar].
///
/// The bar lives in the real bottom-navigation slot, so Flutter reserves its
/// height and every tab's scrollable can use its own bottom padding without
/// having to clear a detached, floating pill. It stays visible while scrolling
/// — the same persistent chrome Material apps use — and follows the theme's
/// surface colors in both light and dark modes.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppRoutes.tabs.indexOf(location);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppChrome.constrain(switch (location) {
        AppRoutes.times => const TimesScreen(),
        AppRoutes.settings => const SettingsScreen(),
        _ => const HomeScreen(),
      }),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
              states,
            ) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onDestinationSelected: (index) => context.go(AppRoutes.tabs[index]),
            destinations: [
              for (final path in AppRoutes.tabs)
                AppRoutes.destinationFor(context, path),
            ],
            backgroundColor: scheme.surfaceContainer,
            indicatorColor: scheme.secondaryContainer,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
              states,
            ) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
          ),
        ),
      ),
    );
  }
}
