import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/ui/widgets/app_chrome.dart';
import 'package:mawaqit/core/ui/widgets/floating_nav_bar.dart';
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

  /// Tab order, start to end.
  ///
  /// The *logical* reading order, so it must not be reversed for RTL — the `Row`
  /// inside the nav bar resolves directionally and flips the layout by itself.
  /// Reversing this list would fight that and mirror the wrong end.
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

  static NavDestination destinationFor(BuildContext context, String path) =>
      NavDestination(
        icon: switch (path) {
          times => Icons.calendar_month_outlined,
          settings => Icons.settings_outlined,
          _ => Icons.home_outlined,
        },
        selectedIcon: switch (path) {
          times => Icons.calendar_month,
          settings => Icons.settings,
          _ => Icons.home,
        },
        label: labelFor(context, path),
      );
}

/// The tabbed shell: a `Scaffold` with `extendBody: true` and the floating
/// frosted nav bar layered over it.
///
/// `extendBody` is what lets the pill *float*. Without it the `Scaffold` paints
/// an opaque body behind the bar and the blur has nothing to blur, so the frost
/// collapses into a flat slab. Every tab therefore renders its own scrollable
/// with [AppChrome.scrollBottomPadding] at the bottom, so the last row is never
/// trapped underneath the pill.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Per-route visibility, so a tab that was scrolled down when you left it
  /// comes back the way you left it, and a fresh tab always starts revealed.
  final Map<String, bool> _visibleByRoute = {};
  final ValueNotifier<bool> _navVisible = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _navVisible.dispose();
    super.dispose();
  }

  void _onNavVisibilityChanged(bool visible) {
    if (!mounted) return;
    final route = GoRouterState.of(context).uri.path;
    if (_visibleByRoute[route] == visible) return;
    setState(() => _visibleByRoute[route] = visible);
    _navVisible.value = visible;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppRoutes.tabs.indexOf(location);
    final visible = _visibleByRoute[location] ?? true;

    return NavVisibilityScope(
      onChanged: _onNavVisibilityChanged,
      child: Scaffold(
        extendBody: true,
        // The nav bar lives in a `Stack` inside the body rather than in the
        // `bottomNavigationBar` slot, and that is deliberate.
        //
        // `FloatingNavBar` frosts itself with a `BackdropFilter`, which samples
        // whatever the engine has already painted *behind* it in the same scene.
        // In the `bottomNavigationBar` slot the Scaffold is free to lay the bar
        // out against a backdrop of its own making, and the blur then samples a
        // flat fill instead of the scrolling content — the bar looks like a solid
        // tinted slab and the "frosted" quality never appears. As a sibling of the
        // content in one `Stack`, the bar provably shares a scene with the list
        // passing beneath it, which is what makes the blur visible while
        // scrolling. This is also how the reference app does it.
        body: Stack(
          children: [
            Positioned.fill(
              child: AppChrome.constrain(switch (location) {
                AppRoutes.times => const TimesScreen(),
                AppRoutes.settings => const SettingsScreen(),
                _ => const HomeScreen(),
              }),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                destinations: [
                  for (final path in AppRoutes.tabs)
                    AppRoutes.destinationFor(context, path),
                ],
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                visible: visible,
                onDestinationSelected: (index) =>
                    context.go(AppRoutes.tabs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How a tab tells the shell "I'm scrolled, get out of the way".
///
/// A plain `InheritedWidget` rather than a provider: this is presentation state
/// that only the widget tree reads, and a tab's `ScrollController` is created in
/// its own `State`, long before the shell could hand it a callback. Every call
/// site is a one-liner — [NavVisibilityScope.report] — so there is nothing to
/// get wrong.
///
/// ```dart
/// NavVisibilityScope.report(context, controller);
/// ```
class NavVisibilityScope extends InheritedWidget {
  const NavVisibilityScope({
    super.key,
    required this.onChanged,
    required super.child,
  });

  final ValueChanged<bool> onChanged;

  /// Reports whether the bar should be on screen for the tab at [context].
  ///
  /// Only legal from a build. For scroll callbacks use [attachScroll], which
  /// resolves the scope once and hands the listener a plain callback.
  static void report(BuildContext context, bool visible) =>
      context.dependOnInheritedWidgetOfExactType<NavVisibilityScope>()
      // Outside the shell (a test harness, a pushed full-screen route) there
      // is nowhere to report to — silently do nothing rather than throw.
      ?.onChanged(visible);

  /// Wraps a scrollable so scrolling down hides the bar and scrolling back up
  /// brings it straight back.
  ///
  /// The notification-based counterpart to [attachScroll], for the tabs that use
  /// a plain `ListView` and have no controller to lend. Preferred there: it needs
  /// no `State`, it disposes itself with the widget, and it works for any
  /// scrollable rather than only ones the caller owns a controller for.
  ///
  /// ```dart
  /// NavVisibilityScope.wrap(context, child: ListView(...))
  /// ```
  ///
  /// Scroll direction comes from [ScrollUpdateNotification]'s pixel delta rather
  /// than the offset alone, so scrolling *up* through a long list reveals the bar
  /// at once instead of waiting for the top — see [attachScroll] for why.
  ///
  /// Returns [child] unchanged when there is no enclosing scope, so a screen can
  /// call this unconditionally.
  static Widget wrap(
    BuildContext context, {
    required Widget child,
    double revealAfter = 24,
  }) {
    final onChanged = context
        .dependOnInheritedWidgetOfExactType<NavVisibilityScope>()
        ?.onChanged;
    if (onChanged == null) return child;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // `ScrollUpdateNotification` only — `OverscrollNotification` has no
        // reliable pixels and would fight the reveal.
        if (notification is! ScrollUpdateNotification) return false;
        if (notification.metrics.axis != Axis.vertical) return false;

        // `scrollDelta` rather than a pixels comparison: it is the *signed*
        // movement of this frame, so a fling that overscrolls back towards zero
        // still reads as "still going down" instead of flipping to a reveal.
        final delta = notification.scrollDelta ?? 0.0;
        if (delta < 0) {
          onChanged(true);
        } else if (notification.metrics.pixels > revealAfter) {
          onChanged(false);
        }
        return false;
      },
      child: child,
    );
  }

  /// Wires [controller] so scrolling down hides the bar and scrolling back up
  /// brings it straight back.
  ///
  /// Returns a `dispose` callback. Call it from the owning `State.dispose` —
  /// a `ScrollController` outlives the widget that attached to it in one case
  /// that matters here: a tab that is rebuilt in place keeps its controller, and
  /// an un-removed listener would keep the old `State` alive through its
  /// closure and report into a disposed shell.
  ///
  /// Scrolling up reveals *immediately* rather than at the top of the list. That
  /// is the behaviour people expect from a bar they just dismissed, and the
  /// alternative — wait for offset to fall back under [revealAfter] — means
  /// scrolling up through a long month feels broken.
  ///
  /// [revealAfter] is in logical pixels of offset, so the bar hides almost
  /// immediately rather than after a whole screen of scrolling.
  static VoidCallback attachScroll(
    BuildContext context,
    ScrollController controller, {
    double revealAfter = 24,
  }) {
    final onChanged = context
        .dependOnInheritedWidgetOfExactType<NavVisibilityScope>()
        ?.onChanged;
    if (onChanged == null) return () {};

    // Seeded from the controller rather than 0 so attaching mid-list does not
    // report a spurious "at the top" on the first frame.
    var lastOffset = controller.hasClients ? controller.offset : 0.0;

    void onScroll() {
      if (!controller.hasClients) return;
      final offset = controller.offset;
      final delta = offset - lastOffset;
      lastOffset = offset;

      if (delta < 0) {
        onChanged(true);
      } else if (offset > revealAfter) {
        onChanged(false);
      }
    }

    controller.addListener(onScroll);
    return () => controller.removeListener(onScroll);
  }

  @override
  bool updateShouldNotify(NavVisibilityScope oldWidget) =>
      oldWidget.onChanged != onChanged;
}
