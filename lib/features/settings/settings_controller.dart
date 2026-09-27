import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/providers/providers.dart';

/// Owns persisted [AppSettings] and applies changes app-wide.
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsRepositoryProvider).load();

  /// Persists [next] and only then publishes it.
  ///
  /// The order matters. Setting `state` first made the UI show the new value
  /// immediately — but if the write then failed (full disk, revoked storage
  /// permission) the state was left advertising a setting that was never saved,
  /// and the next cold start silently reverted it. Publishing after the write
  /// costs one frame of latency and cannot desync the two.
  ///
  /// The failure is deliberately *not* rethrown: every caller is a settings
  /// toggle or a sheet's "Save" button, and letting the error escape would
  /// surface as an unhandled async error with no user-visible explanation. It is
  /// logged and the previous value stays on screen, which is the honest result.
  Future<void> save(AppSettings next) async {
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } catch (error, stack) {
      debugPrint('Settings write failed; keeping the previous value: $error');
      debugPrintStack(stackTrace: stack);
      return;
    }
    if (!ref.mounted) return;
    state = AsyncData(next);

    // Push the new lead-time / tone config into today's already-scheduled
    // notifications instead of waiting for the next daily recompute. Only
    // reached once the write landed, so the alarms always match what is stored.
    unawaited(BackgroundScheduler.rescheduleNow(next));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
