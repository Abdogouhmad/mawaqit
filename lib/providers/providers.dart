import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/const/prayer_keys.dart';
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
    final nowMuted = !current.contains(prayerId);
    final next = await store.setMuted(prayerId, nowMuted);
    state = AsyncData(next);

    // Apply to the exact occurrence first, so the armed alarm — or a ringing
    // one — is silenced even when the reschedule below cannot run (no cached
    // location in GPS mode). See [NotificationService.applyOccurrenceMute].
    final parsed = PrayerKeys.parseOccurrence(prayerId);
    if (parsed != null) {
      final (date, kind) = parsed;
      // Awaited, not fired alongside the reschedule: the reschedule re-posts a
      // quiet card for a muted occurrence, and a cancel that raced it could
      // land afterwards and strip that card back out.
      await ref
          .read(notificationServiceProvider)
          .applyOccurrenceMute(date: date, kind: kind, muted: nowMuted);
    }

    // Re-schedule so the rest of today's adhans honour the fresh mute state.
    final settings = await ref.read(settingsRepositoryProvider).load();
    unawaited(BackgroundScheduler.rescheduleNow(settings));
  }
}
