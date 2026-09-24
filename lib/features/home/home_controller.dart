import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/repositories/prayer_times_repository.dart';
import 'package:mawaqit/data/services/background_scheduler.dart';
import 'package:mawaqit/data/services/prayer_widget_service.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/update_controller.dart';

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
    bool clearError = false,
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
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads prayer times, drives the countdown ticker, and orchestrates
/// notification scheduling for the current day.
class HomeController extends AsyncNotifier<HomeState> {
  Timer? _ticker;
  DateTime? _computedFor;

  /// Next-prayer time the live pre-prayer reminder already fired for — guards
  /// the boundary test below so one reminder rings per occurrence, no matter
  /// how many ticks pass while inside the lead window.
  DateTime? _remindFiredFor;

  @override
  Future<HomeState> build() async {
    state = const AsyncLoading();

    final notificationService = ref.read(notificationServiceProvider);
    try {
      await notificationService.init();
      unawaited(BackgroundScheduler.registerDailyReschedule());
    } catch (_) {}

    // OTA: check once at launch and surface a push notification when a new
    // release exists (silent on failure / when already up to date).
    unawaited(ref.read(updateProvider.notifier).checkForUpdates());

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
    // GPS mode renders instantly from the last known fix, then applies the
    // fresh GPS location in the background once it lands. The user never waits
    // on the GPS chip to see prayer times again.
    if (settings.locationMode == LocationMode.autoGps) {
      final cached = await LocationRepository.cached();
      if (cached != null) {
        final day = _dayFor(cached.latitude, cached.longitude, settings, now);
        final home = _derive(cached, day, settings, now);
        _apply(day, settings, locationShort: cached.displayName);
        unawaited(_refreshFromGps(settings, now, cached));
        return home;
      }
    }

    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .resolve(settings: settings);

      final day = _dayFor(location.latitude, location.longitude, settings, now);
      final home = _derive(location, day, settings, now);
      _apply(day, settings, locationShort: location.displayName);
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

  PrayerDay _dayFor(
    double latitude,
    double longitude,
    AppSettings settings,
    DateTime now,
  ) {
    return ref
        .read(prayerTimesRepositoryProvider)
        .forDate(
          date: now,
          latitude: latitude,
          longitude: longitude,
          parameters: settings.parameters,
        );
  }

  /// Fires notification scheduling for [day] without blocking, and refreshes
  /// the Android home-screen widget with the same day's snapshot.
  void _apply(PrayerDay day, AppSettings settings, {String? locationShort}) {
    unawaited(
      ref
          .read(notificationServiceProvider)
          .scheduleDay(day, settings)
          .catchError((_) {}),
    );
    unawaited(
      PrayerWidgetService.sync(day, settings, locationShort: locationShort),
    );
  }

  /// Polls a fresh GPS fix in the background and, when the coordinates moved
  /// meaningfully, recomputes the day and swaps it into the running state.
  Future<void> _refreshFromGps(
    AppSettings settings,
    DateTime now,
    ResolvedLocation cached,
  ) async {
    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .resolve(settings: settings);
      if (!ref.mounted || location.fromManual) return;

      // resolve() returns the cached fix when GPS is unavailable — no-op.
      final moved =
          (location.latitude - cached.latitude).abs() > 0.0005 ||
          (location.longitude - cached.longitude).abs() > 0.0005;
      if (!moved && location.displayName == cached.displayName) return;

      // Bail if settings changed under us (e.g. the user picked a city).
      final latest = await ref.read(settingsProvider.future);
      if (!ref.mounted ||
          latest.locationMode != LocationMode.autoGps ||
          latest.calculationMethod != settings.calculationMethod ||
          latest.madhab != settings.madhab) {
        return;
      }

      final day = _dayFor(
        location.latitude,
        location.longitude,
        settings,
        DateTime.now(),
      );
      final home = _derive(location, day, settings, DateTime.now());
      _apply(day, settings, locationShort: location.displayName);
      _computedFor = home.now;
      state = AsyncData(home);
    } catch (_) {
      // GPS fix unavailable — the cached snapshot continues to serve.
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
      clearError: true,
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
    final derived = _deriveWith(previous, now);
    final nextChanged = derived.nextPrayer?.time != previous.nextPrayer?.time;
    if (nextChanged && derived.day != null) {
      // A prayer rolled over — refresh the widget's next-prayer highlight and
      // countdown so it never goes stale between app launches.
      unawaited(
        PrayerWidgetService.sync(
          derived.day!,
          ref.read(settingsProvider).value ?? const AppSettings(),
          locationShort: previous.locationName,
        ),
      );
    }

    // A new prayer's adhan time just arrived while the app is open. Fire it
    // directly so it rings + takes over the screen (the scheduled channel sound
    // is unreliable here) instead of waiting for the background path.
    if (previous.currentPrayer != null &&
        derived.currentPrayer != null &&
        previous.currentPrayer!.kind != derived.currentPrayer!.kind) {
      _maybeFireAdhan(derived);
    }

    // The pre-prayer reminder's lead-time boundary just arrived while the app
    // is open. Fire it directly too (direct chime, scheduled card cancelled)
    // so the real reminder rings the selected tone instead of a frozen channel
    // sound. The 60s freshness window mirrors the adhan guard: if the app was
    // backgrounded across the boundary and resumed much later, the scheduled
    // card already covered it and re-ringing would double up.
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final next = derived.nextPrayer;
    if (next != null && settings.prePrayerEnabled && settings.leadMinutes > 0) {
      final boundary = next.time.subtract(
        Duration(minutes: settings.leadMinutes),
      );
      final sinceBoundary = now.difference(boundary).inSeconds;
      if (sinceBoundary >= 0 &&
          sinceBoundary <= 60 &&
          _remindFiredFor != next.time) {
        _remindFiredFor = next.time;
        unawaited(_maybeFireReminder(derived, settings));
      }
    }

    state = AsyncData(derived);
  }

  Future<void> _maybeFireReminder(HomeState home, AppSettings settings) async {
    final day = home.day;
    final next = home.nextPrayer;
    if (day == null || next == null) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .firePrayerReminder(day: day, prayer: next, settings: settings);
    } catch (_) {
      // The scheduled card still covers this occurrence — nothing to do.
    }
  }

  Future<void> _maybeFireAdhan(HomeState home) async {
    final settings = ref.read(settingsProvider).value;
    final day = home.day;
    final current = home.currentPrayer;
    if (settings == null || day == null || current == null) return;
    // Only fire when the rollover is fresh — if the app was backgrounded across
    // a prayer time and resumed later, the scheduled alarm already handled it
    // and re-ringing on resume would double up.
    if (DateTime.now().difference(current.time).inSeconds > 45) return;
    try {
      await ref
          .read(notificationServiceProvider)
          .firePrayerAdhan(day: day, prayer: current, settings: settings);
    } catch (_) {
      // The scheduled alarm still covers the background case — nothing to do.
    }
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
            state = AsyncData(
              previous.copyWith(now: DateTime.now(), error: error.toString()),
            );
          }
        });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
