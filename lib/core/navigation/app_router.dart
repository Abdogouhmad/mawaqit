import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/navigation/app_navigator.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';

/// The app's router.
///
/// Four flat tab routes, all rendered by [AppShell], which switches on the path
/// itself. That is deliberately not four sibling `ShellRoute`s: a shell per tab
/// would rebuild — and re-run its scroll controllers — on every tab change, and
/// would give each tab its own back stack, so backing out of Settings would land
/// on a *stale* Home rather than the one the user actually left.
///
/// Unknown paths fall through to `/` instead of throwing a 404 screen: the only
/// internal links are the four tabs, so an unknown path means a stale deep link
/// from an older version of the app, and Home is the correct thing to show.
GoRouter createRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    // Shared with the notification service, which pushes the raw full-screen
    // adhan `PageRoute` from outside the widget tree. Sharing one key puts that
    // route above the shell instead of inside one tab's stack.
    navigatorKey: appNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const AppShell()),
      GoRoute(path: AppRoutes.times, builder: (_, _) => const AppShell()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const AppShell()),
    ],
    errorBuilder: (context, state) => const AppShell(),
  );
}
