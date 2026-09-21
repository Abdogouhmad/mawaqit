import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/providers/providers.dart';

/// Owns persisted [AppSettings] and applies changes app-wide.
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() =>
      ref.read(settingsRepositoryProvider).load();

  Future<void> save(AppSettings next) async {
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);

    // Push the new lead-time / tone config into today's already-scheduled
    // notifications instead of waiting for the next daily recompute.
    unawaited(BackgroundScheduler.rescheduleNow(next));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);