import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/home/home_screen.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/settings_screen.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';

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

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/update': (_) => const OtaUpdateScreen(),
      },
    );
  }
}