import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/app.dart';
import 'package:mawaqit/core/utils/timezone_setup.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimezoneSetup.ensureInitialized();

  // Registers the WorkManager callback dispatcher (runs the background isolate).
  BackgroundScheduler.initialize();

  runApp(const ProviderScope(child: MawaqitApp()));
}