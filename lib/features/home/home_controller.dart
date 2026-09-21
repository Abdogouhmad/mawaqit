import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';

/// Immutable snapshot of everything the Home screen renders.
@immutable
class HomeState {
  const HomeState({
    required this.now,
    this.day,
    this.locationName = '',
    this.fromManual = false,
    this.currentPrayer,
    this.nextPrayer,
    this.nextIn = Duration.zero,
    this.progress = 0,
    this.methodLabel = '',
    this.isLoading = true,
    this.error,
  });

  final DateTime now;
  final PrayerDay? day;
  final String locationName;
  final bool fromManual;
  final PrayerTime? currentPrayer;
  final PrayerTime? nextPrayer;
  final Duration nextIn;
  final double progress;
  final String methodLabel;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    DateTime? now,
    PrayerDay? day,
    String? locationName,
    bool? fromManual,
    PrayerTime? currentPrayer,
    PrayerTime? nextPrayer,
    Duration? nextIn,
    double? progress,
    String? methodLabel,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      now: now ?? this.now,
      day: day ?? this.day,
      locationName: locationName ?? this.locationName,
      fromManual: fromManual ?? this.fromManual,
      currentPrayer: currentPrayer ?? this.currentPrayer,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      nextIn: nextIn ?? this.nextIn,
      progress: progress ?? this.progress,
      methodLabel: methodLabel ?? this.methodLabel,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Loads prayer times, drives the countdown ticker, and orchestrates
/// notification scheduling for the current day.
class HomeController extends AsyncNotifier<HomeState> {
  Timer? _ticker;
  DateTime? _computedFor;

  @override
  Future<HomeState> build() async {
    state = const AsyncLoading();

    final notificationService = ref.read(notificationServiceProvider);
    try {
      await notificationService.init();
      unawaited(BackgroundScheduler.registerDailyReschedule());
    } catch (_) {}

    final settings = await ref.watch(settingsProvider.future);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(() => _ticker?.cancel());

    final home = await _resolveOrFallback(settings, DateTime.now());
    _computedFor = home.now;
    return home;
  }

  Future<HomeState> _resolveOrFallback(
    AppSettings settings,
    DateTime now,
  ) async {
    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .resolve(settings: settings);

      final day = ref.read(prayerTimesRepositoryProvider).forDate(
            date: now,
            latitude: location.latitude,
            longitude: location.longitude,
            parameters: settings.parameters,
          );

      final home = _derive(location, day, settings, now);
      unawaited(
        ref
            .read(notificationServiceProvider)
            .scheduleDay(day, settings)
            .catchError((_) {}),
      );
      return home;
    } catch (error) {
final previous = state.hasValue ? state.value : null;
      return HomeState(
        now: now,
        day: previous?.day,
        locationName: previous?.locationName ?? '',
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  HomeState _derive(
    ResolvedLocation location,
    PrayerDay day,
    AppSettings settings,
    DateTime now,
  ) {
    return _deriveWith(
      HomeState(
        now: now,
        day: day,
        locationName: location.displayName,
        fromManual: location.fromManual,
        methodLabel: PrayerTimesRepository.shortLabel(
          settings.calculationMethod,
        ),
      ),
      now,
    );
  }

  HomeState _deriveWith(HomeState base, DateTime now) {
    final day = base.day;
    if (day == null) return base;

    PrayerTime? current;
    PrayerTime? next;
    for (final p in day.prayers) {
      if (!p.time.isAfter(now)) {
        current = p;
      } else {
        next = p;
        break;
      }
    }
    if (next == null) {
      next = PrayerTime(kind: PrayerKind.fajr, time: day.nextDayFajr);
      current ??= day.prayers.last;
    }

    final start = current?.time ?? DateTime(now.year, now.month, now.day);
    final duration = next.time.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    final progress = duration <= 0 ? 0.0 : (elapsed / duration).clamp(0.0, 1.0);

    return base.copyWith(
      now: now,
      day: day,
      currentPrayer: current,
      nextPrayer: next,
      nextIn: next.time.difference(now).isNegative
          ? Duration.zero
          : next.time.difference(now),
      progress: progress,
      isLoading: false,
      error: null,
    );
  }

  void _tick() {
    final previous = state.hasValue ? state.value : null;
    if (previous == null) return;
    final now = DateTime.now();

    if (_computedFor == null || !_sameDay(_computedFor!, now)) {
      _reload(previous);
      return;
    }
    state = AsyncData(_deriveWith(previous, now));
  }

  void _reload(HomeState previous) {
    ref
        .read(settingsProvider.future)
        .then((settings) async {
          if (ref.mounted) state = const AsyncLoading();
          final home = await _resolveOrFallback(settings, DateTime.now());
          _computedFor = home.now;
          if (ref.mounted) state = AsyncData(home);
        })
        .catchError((Object error) {
          if (ref.mounted) {
            state = AsyncData(previous.copyWith(
              now: DateTime.now(),
              error: error.toString(),
            ));
          }
        });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);