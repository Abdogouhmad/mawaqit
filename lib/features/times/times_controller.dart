import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/data/prayer/prayer_times_service.dart';
import 'package:mawaqit/features/home/home_controller.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';

/// How far one prayer's time moves between the first and last day of a month.
///
/// The answer to the question a monthly prayer table exists to answer: does Asr
/// creep later this month, or earlier? Reading it off the table means comparing
/// two cells nineteen rows apart, which is exactly the kind of comparison a
/// narrow phone makes impossible.
@immutable
class TimesShift {
  const TimesShift({required this.kind, required this.minutes});

  final PrayerKind kind;

  /// Last day's time minus first day's time, in whole minutes.
  ///
  /// Negative when the prayer falls earlier as the month goes on, positive when
  /// it falls later, zero when it does not move.
  final int minutes;

  bool get isEarlier => minutes < 0;

  bool get isLater => minutes > 0;
}

/// Snapshot of the monthly Times tab.
@immutable
class TimesState {
  TimesState({
    required this.month,
    required this.days,
    this.locationName = '',
    this.isLoading = true,
    this.error,
  });

  /// First day of the displayed month, at local midnight.
  final DateTime month;

  /// One entry per day of [month], in calendar order.
  final List<PrayerDay> days;

  final String locationName;
  final bool isLoading;
  final String? error;

  bool get hasLocation => days.isNotEmpty;

  /// How far each prayer's time moves across [month], or `null` when that cannot
  /// be stated honestly.
  ///
  /// Memoised rather than recomputed per build: the day list is immutable for a
  /// given [TimesState], and this is read by a widget that rebuilds on every
  /// scroll-driven header repaint. `late final` is why the constructor is not
  /// `const` — a lazily derived value cannot live on a const instance.
  late final List<TimesShift>? shifts = _computeShifts();

  List<TimesShift>? _computeShifts() {
    // One day has no span to measure.
    if (days.length < 2) return null;

    final first = days.first;
    final last = days.last;
    final result = <TimesShift>[];

    for (final kind in PrayerKind.five) {
      final from = first.prayer(kind)?.time;
      final to = last.prayer(kind)?.time;
      if (from == null || to == null) return null;

      final minutes = _driftMinutes(from, to);

      // Above roughly three hours the change is not a drift in the schedule, it
      // is the calculation flipping behaviour mid-month — an extreme-twilight
      // fallback at high latitude, or a sunrise/sunset crossing the method's
      // angle. Printing "Isha +240m" as a fact would be worse than printing
      // nothing, so the whole card is dropped instead.
      if (minutes.abs() > maxPlausibleShiftMinutes) return null;

      result.add(TimesShift(kind: kind, minutes: minutes));
    }
    return result;
  }

  /// Signed change in *time of day* from [from] to [to], the short way round.
  ///
  /// The two instants are on different dates a month apart, so subtracting them
  /// would report about 43,200 minutes for every prayer in every month — the card
  /// would always read as an impossible change and would always be suppressed.
  /// What is being asked is "does this prayer fall earlier or later in the day",
  /// so only the clock time is compared.
  ///
  /// Wrapped to ±12h so a prayer crossing midnight (Isha at 23:52 becoming
  /// 00:03, which does happen) reads as the eleven minutes it moved rather than as
  /// a 1,429-minute jump.
  static int _driftMinutes(DateTime from, DateTime to) {
    const minutesPerDay = 24 * 60;
    var diff = (to.hour * 60 + to.minute) - (from.hour * 60 + from.minute);
    diff = diff % minutesPerDay;
    if (diff > minutesPerDay ~/ 2) diff -= minutesPerDay;
    return diff;
  }

  /// Beyond this, [shifts] is treated as untrustworthy rather than reported.
  static const int maxPlausibleShiftMinutes = 180;

  /// How far either side of the current month the calendar may be paged.
  ///
  /// Without a bound, `DateTime(y, m + delta)` keeps rolling forward — a held
  /// chevron reaches the year 3000, where the solar calculation is meaningless
  /// and the header is a lie. A year either way covers "planning next Ramadan"
  /// and "checking last year" without pretending to be an ephemeris.
  static const int maxMonthsFromNow = 12;

  /// First month the calendar will page to.
  ///
  /// Public because the month picker offers the same range as the chevrons; a
  /// picker that could select a month the chevrons then refuse to reach would be
  /// two sources of truth for one bound.
  static DateTime get earliestMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month - maxMonthsFromNow);
  }

  /// Last month the calendar will page to.
  static DateTime get latestMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + maxMonthsFromNow);
  }

  /// Whether [candidate] falls inside the paged range.
  static bool isWithinBounds(DateTime candidate) =>
      !candidate.isBefore(earliestMonth) && !candidate.isAfter(latestMonth);

  bool get isCurrentMonth => _isSameMonth(month, DateTime.now());

  bool get canStepBack => month.isAfter(earliestMonth);

  bool get canStepForward => month.isBefore(latestMonth);

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  TimesState copyWith({
    DateTime? month,
    List<PrayerDay>? days,
    String? locationName,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => TimesState(
    month: month ?? this.month,
    days: days ?? this.days,
    locationName: locationName ?? this.locationName,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Loads the whole month for the current location and settings.
///
/// Deliberately reuses [homeControllerProvider]'s already-resolved location
/// rather than resolving again: a second `Geolocator.getCurrentPosition` would
/// mean a second GPS round trip and a second permission prompt when the user
/// opens this tab seconds after Home.
class TimesController extends AsyncNotifier<TimesState> {
  @override
  Future<TimesState> build() async {
    final now = DateTime.now();
    final settings = await ref.read(settingsProvider.future);

    // Rebuild when the month is paged, or when anything that moves the times
    // changes. Watching (rather than reading) is right here precisely *because*
    // this notifier owns no side effects — unlike the home controller, whose
    // `build` re-initialises the alarm pipeline.
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (_, next) {
      final value = next.value;
      if (value == null) return;
      _recompute(value);
    });

    final home = await ref.read(homeControllerProvider.future);
    if (!home.hasLocationResolved) {
      return TimesState(
        month: DateTime(now.year, now.month),
        days: const [],
        locationName: home.locationName,
        isLoading: false,
      );
    }

    final days = const PrayerTimesService().forMonth(
      month: DateTime(now.year, now.month),
      latitude: home.latitude!,
      longitude: home.longitude!,
      parameters: settings.parameters,
    );

    return TimesState(
      month: DateTime(now.year, now.month),
      days: days,
      locationName: home.locationName,
      isLoading: false,
    );
  }

  /// Pages to [month], or forward/back by [delta] months from the current one.
  Future<void> goToMonth(DateTime month) async {
    final previous = state.value;
    if (previous == null) return;

    // The single gate on the paging range. Enforced here rather than only on the
    // chevrons because the month picker reaches this method too, and a control
    // that disables itself is not a guarantee: the same month is also selectable
    // by keyboard and by screen reader.
    if (!TimesState.isWithinBounds(month)) return;

    final settings = await ref.read(settingsProvider.future);
    final home = await ref.read(homeControllerProvider.future);
    if (!home.hasLocationResolved) return;

    // Show the new header immediately and fill it in, rather than dropping back
    // to a spinner: paging a month is a sub-10 ms computation and a full-screen
    // spinner for that reads as a stutter.
    //
    // `isLoading` is what separates "this month is on its way" from "there is no
    // location" for the screen. Without it the empty `days` here reads as a lost
    // location and the tab flashes its "pick a location" state on every page.
    state = AsyncData(
      previous.copyWith(
        month: DateTime(month.year, month.month),
        days: const [],
        isLoading: true,
      ),
    );

    final days = const PrayerTimesService().forMonth(
      month: DateTime(month.year, month.month),
      latitude: home.latitude!,
      longitude: home.longitude!,
      parameters: settings.parameters,
    );
    if (!ref.mounted) return;
    state = AsyncData(previous.copyWith(days: days, isLoading: false));
  }

  Future<void> step(int delta) async {
    final current = state.value?.month ?? DateTime.now();
    await goToMonth(DateTime(current.year, current.month + delta));
  }

  /// Returns the calendar to the current month. A no-op when already there.
  Future<void> goToCurrentMonth() => goToMonth(DateTime.now());

  Future<void> _recompute(AppSettings settings) async {
    final previous = state.value;
    if (previous == null || previous.days.isEmpty) return;
    final home = await ref.read(homeControllerProvider.future);
    if (!home.hasLocationResolved || !ref.mounted) return;

    final days = const PrayerTimesService().forMonth(
      month: previous.month,
      latitude: home.latitude!,
      longitude: home.longitude!,
      parameters: settings.parameters,
    );
    if (!ref.mounted) return;
    state = AsyncData(previous.copyWith(days: days, clearError: true));
  }
}

final timesControllerProvider =
    AsyncNotifierProvider<TimesController, TimesState>(TimesController.new);
