import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';
import 'package:mawaqit/data/services/notification_service.dart';

/// Infrastructure providers. Feature controllers live beside their screens.

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final locationRepositoryProvider =
    Provider<LocationRepository>((ref) => LocationRepository());

final prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>((ref) => const PrayerTimesRepository());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);