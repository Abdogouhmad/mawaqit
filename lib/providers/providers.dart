import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/data/services/muted_prayers_store.dart';
import 'package:mawaqit/data/services/notification_service.dart';

/// Infrastructure providers. Feature controllers live beside their screens.

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(),
);

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>(
  (ref) => const PrayerTimesRepository(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final mutedPrayersStoreProvider = Provider<MutedPrayersStore>(
  (ref) => MutedPrayersStore(),
);

/// The set of muted occurrence ids (`2026-09-21_maghrib`), shared with the
/// native lockscreen card via the same prefs file.
final mutedPrayersProvider =
    AsyncNotifierProvider<MutedPrayersController, Set<String>>(
      MutedPrayersController.new,
    );

class MutedPrayersController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.read(mutedPrayersStoreProvider).load();

  bool isMuted(String prayerId) => state.value?.contains(prayerId) ?? false;

  Future<void> toggle(String prayerId) async {
    final store = ref.read(mutedPrayersStoreProvider);
    final current = state.value ?? await store.load();
    final next = await store.setMuted(prayerId, !current.contains(prayerId));
    state = AsyncData(next);

    // Re-schedule so today's adhan honours the fresh mute state at fire time.
    final settings = await ref.read(settingsRepositoryProvider).load();
    unawaited(BackgroundScheduler.rescheduleNow(settings));
  }
}
