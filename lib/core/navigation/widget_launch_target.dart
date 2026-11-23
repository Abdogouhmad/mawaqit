import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/src/home_widget/widget_tokens.dart';

/// Turns a home-screen widget URI into a route the app will accept.
///
/// Both the cold-start path (`initiallyLaunchedFromWidget`) and the warm tap
/// stream go through here. They used to each call a private copy in `main.dart`,
/// which is exactly the kind of duplication that lets one path drift — so the
/// rule now lives in one pure function with tests.
///
/// The URI is launcher-supplied input. Only a path that is already one of our
/// tabs is accepted; anything else is ignored rather than handed to GoRouter,
/// whose errorBuilder is not a user-friendly place to land after a widget tap.
abstract final class WidgetLaunchTarget {
  const WidgetLaunchTarget._();

  /// The tab route carried by [uri], or `null` when it is not a widget tap we
  /// understand. Query parameters (notably the plugin's `homeWidget` marker)
  /// are deliberately ignored.
  static String? route(Uri? uri) {
    if (uri?.scheme != 'mawaqit') return null;
    final path = uri?.path;
    if (path == null || path.isEmpty) return null;
    return AppRoutes.tabs.contains(path) ? path : null;
  }

  /// Whether [uri] is the URI the checked-in widget DSL actually emits.
  ///
  /// Used by tests to keep the DSL and the parser in lockstep; useful at runtime
  /// only as a cheap sanity check for diagnostic builds.
  static bool isWidgetUri(Uri? uri) =>
      uri?.toString() == WidgetTokens.launchUrl;
}
