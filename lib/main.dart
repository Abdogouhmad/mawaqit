import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/app.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimezoneSetup.ensureInitialized();

  // Captures version/versionCode once for the OTA updater.
  await AppInfo.init();

  // Registers the WorkManager callback dispatcher (runs the background isolate).
  BackgroundScheduler.initialize();

  runApp(const ProviderScope(child: MawaqitApp()));
}