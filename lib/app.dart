import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/navigation/app_navigator.dart';
import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/app_theme.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/l10n/ambient_l10n.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/home/home_screen.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/settings_screen.dart';

class MawaqitApp extends ConsumerWidget {
  const MawaqitApp({super.key});

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

    return MaterialApp(
      // The app's own strings plus every Material/Cupertino/Widgets one, so
      // switching locale also switches built-in dialogs, tooltips and text
      // selection menus. `ar` additionally flips the whole tree to RTL, which
      // is what a right-to-left language needs from the framework.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // `null` (AppLanguage.system) is the important value here: it hands
      // resolution back to the framework's device-locale matching. Passing a
      // locale that is not in supportedLocales would throw, so the setting only
      // ever names one of the two languages we actually ship.
      locale: switch (settings?.language.languageCode) {
        final String code => Locale(code),
        null => null,
      },
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      // Arabic drops the Latin letter-spacing: see AppTheme._untacked.
      theme: AppTheme.light(arabic: isArabic),
      darkTheme: AppTheme.dark(arabic: isArabic),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
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
        // reading the locale again: `supportedLocales` is exactly {en, ar} and
        // `locale:` is either null or one of them, so the framework's own
        // resolution provably lands on the same value — and computing it once
        // means the theme, the clock formatter and the notification copy can
        // never disagree about which language the app is in.
        TimeFormatter.locale(effective.languageCode);
        AmbientL10n.locale = effective;

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
