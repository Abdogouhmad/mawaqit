import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'package:mawaqit/app.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/src/home_widget/prayer_widget.home_widget.dart';

Future<void> main() async {
  // A throw anywhere in here leaves the process sitting on the launch window's
  // blank background — on a light-theme device, a white screen with no Flutter
  // frame and no way back. `PrayerWidgetHomeWidget` below is one real source of
  // exactly that (a stale native install answers `MissingPluginException`), so
  // the whole bootstrap runs inside a guarded zone that still produces a frame.
  await runZonedGuarded(
    () async {
      // Inside the zone, not before it. The binding records the zone it was
      // created in and `runApp` below asserts it is the same one, so
      // initialising out here and running the app in there trips "Zone mismatch"
      // and leaves every zone-scoped callback — timers, platform channels,
      // `Image` decoding — resolving against whichever zone happened to be
      // active when it was registered.
      WidgetsFlutterBinding.ensureInitialized();

      await TimezoneSetup.ensureInitialized();

      // Captures version/versionCode once for the OTA updater. Never throws.
      await AppInfo.init();

      // Registers the WorkManager callback dispatcher (runs the background isolate).
      BackgroundScheduler.initialize();

      // Home-screen widget launch, resolved *before* the first frame so the app
      // opens on the tab the card was showing instead of flashing Home first.
      MawaqitApp.launchRoute = await _launchRoute();

      runApp(const ProviderScope(child: MawaqitApp()));

      // Warm launches. A tap while the app is already alive is delivered to the
      // existing singleTop activity as a second intent, so there is no cold-start
      // URL left to read — this stream is the only signal that it happened.
      unawaited(_followWidgetTaps());
    },
    (error, stack) {
      // debugPrint so it reaches logcat instead of vanishing; the zone handler is
      // the last thing standing between a bootstrap failure and a silent window.
      debugPrint('mawaqit: bootstrap failed\n$error\n$stack');
    },
  );
}

/// The tab the home-screen widget asked for, or `null` for a normal start.
///
/// The generated helper has already confirmed the URI is *this* widget's, so the
/// only job left is turning its path into one of the app's routes — and refusing
/// anything that is not one. The path is launcher-supplied input; feeding an
/// unrecognised route to `GoRouter` would fall through to its `errorBuilder`.
Future<String?> _launchRoute() async {
  try {
    return _routeFrom(
      await PrayerWidgetHomeWidget.initiallyLaunchedFromWidget(),
    );
  } catch (_) {
    // Desktop dev run, a test harness, or a native install that predates the
    // plugin. All ordinary: the app just starts on Home.
    return null;
  }
}

/// Navigates for widget taps that arrive while the app is already running.
Future<void> _followWidgetTaps() async {
  // Probed before subscribing, because subscribing cannot be made safe.
  // `EventChannel.receiveBroadcastStream` catches a failed `listen` internally
  // and reports it with `FlutterError.reportError` — it never puts the error on
  // the stream, so the `try` around the `await for` below would never see it and
  // the exception surfaces as an unhandled one on every launch.
  //
  // The channel is missing whenever there is no native side to answer it: a stale
  // install that predates the plugin, or a host with no native side at all
  // (desktop, web, a test host). It does not come back, so there is nothing to
  // retry — probe and skip instead of subscribing to a stream that cannot open.
  // Both channels belong to the same plugin, so one call answers for both.
  try {
    await HomeWidget.initiallyLaunchedFromHomeWidget();
  } catch (_) {
    return;
  }

  try {
    await for (final uri in PrayerWidgetHomeWidget.widgetClicked) {
      final route = _routeFrom(uri);
      if (route != null) MawaqitApp.navigateTo(route);
    }
  } catch (_) {
    // The event channel dies with the engine; nothing to recover.
  }
}

/// [uri]'s path as one of the app's tab routes, or `null` if it is not one.
String? _routeFrom(Uri? uri) {
  final path = uri?.path;
  if (path == null || path.isEmpty) return null;
  return AppRoutes.tabs.contains(path) ? path : null;
}
