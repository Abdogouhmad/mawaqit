import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/providers/providers.dart';

/// Owns persisted [AppSettings] and applies changes app-wide.
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() =>
      ref.read(settingsRepositoryProvider).load();

  Future<void> save(AppSettings next) async {
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);