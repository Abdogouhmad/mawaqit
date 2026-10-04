import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/const/app_constants.dart';
import 'package:mawaqit/core/navigation/app_router.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/core/ui/theme/motion.dart';
import 'package:mawaqit/core/ui/widgets/blur_surface.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/ambient_l10n.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

class MawaqitApp extends ConsumerWidget {
  const MawaqitApp({super.key});

  /// Where the app should open, set once by `main()` before the first frame.
  ///
  /// `null` means "no launch request" — a normal launcher start — and resolves
  /// to the Home tab. Anything that arrives from outside (today: the
  /// home-screen widget) goes through this instead of pushing a route after the
  /// fact, so the app never renders a frame of Home before jumping.
  static String? launchRoute;

  /// Built once and reused for the app's lifetime.
  ///
  /// A `GoRouter` owns its own `RouteInformationProvider` and history list;
  /// constructing a fresh one on every rebuild (which is what an inline
  /// `router:` argument would do, since `MawaqitApp` rebuilds whenever settings
  /// change) would throw away the navigation history and reset the tab to Home.
  ///
  /// Static finals initialise lazily on first read, and the first read is the
  /// `routerConfig:` below — which cannot happen before `main()` has finished
  /// assigning [launchRoute]. So the launch route is reliably picked up without
  /// giving up the single-instance guarantee.
  static final GoRouter _router = createRouter(
    initialLocation: launchRoute ?? AppRoutes.home,
  );

  /// Switches to [route], or does nothing if it is not one of the app's routes.
  ///
  /// Exists for callers that have no `BuildContext` of their own and cannot wait
  /// for a frame: a home-screen widget tap arrives on a stream, not as a gesture,
  /// so there is no widget below it to hang a context off. Reading the context off
  /// [appNavigatorKey] instead would mean touching a `BuildContext` after an
  /// `await`, which is unsound and which the analyzer rejects.
  static void navigateTo(String route) {
    if (AppRoutes.tabs.contains(route)) _router.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).hasValue
        ? ref.watch(settingsProvider).value
        : null;
    final themeMode = switch (settings?.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final palette = settings?.palette;

    // The language the app is actually rendering in, resolved once and reused
    // for the locale override, the theme's Arabic typography, and the ambient
    // locale the service layer reads. `locale:` below still needs the raw
    // override so that "system" stays live to device-locale changes, but
    // everything else wants the narrowed answer.
    final effective = resolveAppLocale(
      settings?.language ?? AppLanguage.system,
      PlatformDispatcher.instance.locale,
    );
    final isArabic = effective.languageCode == 'ar';

    // A palette switch must take effect now, not on the next cold start: the
    // themes are cached, and a stale cache would leave Settings showing the new
    // palette while every other screen kept the old colours.
    final cacheKey = '${palette?.name}-${themeMode.name}-$isArabic';
    if (_lastCacheKey != cacheKey) {
      _lastCacheKey = cacheKey;
      AppTheme.invalidateCache();
    }

    return MaterialApp.router(
      // The app's own strings plus every Material/Cupertino/Widgets one, so
      // switching locale also switches built-in dialogs, tooltips and text
      // selection menus. `ar` additionally flips the whole tree to RTL.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // `null` (AppLanguage.system) is the important value here: it hands
      // resolution back to the framework's device-locale matching. Passing a
      // locale that is not in supportedLocales would throw, so the setting only
      // ever names one of the three languages we actually ship.
      locale: switch (settings?.language.languageCode) {
        final String code => Locale(code),
        null => null,
      },
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // Arabic drops the Latin letter-spacing: see AppTextTheme.untacked.
      theme: AppTheme.light(
        palette: palette ?? AppPalette.emerald,
        arabic: isArabic,
      ),
      darkTheme: AppTheme.dark(
        palette: palette ?? AppPalette.emerald,
        arabic: isArabic,
      ),
      themeMode: themeMode,
      builder: (context, child) {
        // Keep the shared clock formatter in step with the device's 12/24-hour
        // setting. Done here rather than per-call because notifications and the
        // home widget format times outside the widget tree, and this builder is
        // the one place that sees the authoritative value — and it re-runs when
        // the system setting changes under a running app.
        TimeFormatter.use24HourFormat(
          MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false,
        );

        // The language half of the same problem. Reuses [effective] rather than
        // reading the locale again: `supportedLocales` is exactly {en, ar, fr}
        // and `locale:` is either null or one of them, so the framework's own
        // resolution provably lands on the same value — and computing it once
        // means the theme, the clock formatter and the notification copy can
        // never disagree about which language the app is in.
        TimeFormatter.locale(effective.languageCode);
        AmbientL10n.locale = effective;

        final content = child ?? const SizedBox.shrink();
        // OR-ed with the platform's own "remove blur" signal rather than
        // replacing it: Android 17 exposes a system-wide blur toggle, and
        // honouring it is free here.
        final reduceTransparency =
            (settings?.reduceTransparency ?? false) ||
            MediaQuery.maybeDisableAnimationsOf(context) == true;

        // Wrapping *here* rather than at each BlurSurface means the setting is
        // inherited by the adhan overlay, sheets and dialogs too, and it costs
        // one wrapper rather than a provider read per surface.
        return ReduceTransparency(
          enabled: reduceTransparency,
          child: MotionPreferences(
            reduceMotion: settings?.reduceMotion ?? false,
            child: content,
          ),
        );
      },
    );
  }

  static String? _lastCacheKey;
}
