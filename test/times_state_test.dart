import 'package:flutter_test/flutter_test.dart';

import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/times/times_controller.dart';

/// Builds a day whose prayers sit a per-kind number of minutes past noon.
///
/// Each prayer is anchored to a time *of day* rather than to the date, so an
/// offset of zero means "the same time every day". Anchoring to the date instead
/// would put every unmoved prayer 30 days apart, which is not a schedule.
PrayerDay _day(DateTime date, Map<PrayerKind, int> offsets) => PrayerDay(
  date: date,
  prayers: PrayerKind.five
      .map(
        (k) => PrayerTime(
          kind: k,
          time: DateTime(date.year, date.month, date.day, 12, offsets[k] ?? 0),
        ),
      )
      .toList(),
  sunrise: date.add(const Duration(hours: 6)),
  sunset: date.add(const Duration(hours: 18)),
  solarNoon: date.add(const Duration(hours: 12)),
  nextDayFajr: date.add(const Duration(days: 1, hours: 5)),
  methodName: 'Test',
);

PrayerDay _uniformDay(DateTime date) => _day(date, const {});

void main() {
  group('TimesState.shifts', () {
    test('reports each prayer moving later across the month', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _day(DateTime(2026, 3, 1), {PrayerKind.fajr: 300}),
          _day(DateTime(2026, 3, 31), {PrayerKind.fajr: 315}),
        ],
      );

      final shifts = state.shifts;
      expect(shifts, hasLength(5));
      expect(shifts!.map((s) => s.kind), PrayerKind.five);
      // Every other prayer is unmoved, so only Fajr should report a direction.
      expect(shifts.where((s) => s.isLater), hasLength(1));
      expect(shifts.first.minutes, 15);
      expect(shifts.first.isEarlier, isFalse);
    });

    test('reports a prayer moving earlier as negative', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _day(DateTime(2026, 3, 1), {PrayerKind.asr: 600}),
          _day(DateTime(2026, 3, 31), {PrayerKind.asr: 590}),
        ],
      );

      final asr = state.shifts!.firstWhere((s) => s.kind == PrayerKind.asr);
      expect(asr.minutes, -10);
      expect(asr.isEarlier, isTrue);
      expect(asr.isLater, isFalse);
    });

    test('a month that does not move is reported as unchanged, not hidden', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _uniformDay(DateTime(2026, 3, 1)),
          _uniformDay(DateTime(2026, 3, 31)),
        ],
      );

      expect(state.shifts, hasLength(5));
      expect(
        state.shifts!.every(
          (s) => s.minutes == 0 && !s.isEarlier && !s.isLater,
        ),
        isTrue,
      );
    });

    test('a single day has no span and reports nothing', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [_uniformDay(DateTime(2026, 3, 1))],
      );

      expect(state.shifts, isNull);
    });

    test('a shift past the plausible ceiling drops the whole card', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _day(DateTime(2026, 3, 1), {PrayerKind.fajr: 300}),
          _day(
            DateTime(2026, 3, 31),
            // Just over the three-hour ceiling: a real calculation flipping
            // behaviour mid-month, not a schedule that drifted.
            {PrayerKind.fajr: 300 + TimesState.maxPlausibleShiftMinutes + 1},
          ),
        ],
      );

      // Not "the other four still render": a card claiming Asr is steady while
      // omitting the prayer beside it is not the truth about the month.
      expect(state.shifts, isNull);
    });

    test('a shift exactly at the ceiling is still reported', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _day(DateTime(2026, 3, 1), {PrayerKind.fajr: 300}),
          _day(DateTime(2026, 3, 31), {
            PrayerKind.fajr: 300 + TimesState.maxPlausibleShiftMinutes,
          }),
        ],
      );

      expect(state.shifts, hasLength(5));
    });

    test('is memoised, so a header repaint cannot change the answer', () {
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _uniformDay(DateTime(2026, 3, 1)),
          _uniformDay(DateTime(2026, 3, 31)),
        ],
      );

      expect(identical(state.shifts, state.shifts), isTrue);
    });

    test('a prayer crossing midnight reads as the minutes it moved', () {
      // Isha at 23:52 becoming 00:03 is eleven minutes later, not 1,429. Without
      // the wrap this is the case that suppresses the whole card.
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _day(DateTime(2026, 3, 1), {PrayerKind.isha: 12 * 60 - 8}),
          _day(DateTime(2026, 3, 31), {PrayerKind.isha: 12 * 60 + 3}),
        ],
      );

      final isha = state.shifts!.firstWhere((s) => s.kind == PrayerKind.isha);
      expect(isha.minutes, 11);
      expect(isha.isLater, isTrue);
    });

    test('the span between the first and last day is not itself the drift', () {
      // Every prayer unmoved, yet the last day is thirty days after the first.
      // Comparing the instants would put every entry past the three-hour ceiling
      // and suppress the card permanently.
      final state = TimesState(
        month: DateTime(2026, 3),
        isLoading: false,
        days: [
          _uniformDay(DateTime(2026, 3, 1)),
          _uniformDay(DateTime(2026, 3, 31)),
        ],
      );

      expect(state.shifts, hasLength(5));
      expect(state.shifts!.every((s) => s.minutes == 0), isTrue);
    });
  });

  group('TimesState paging bounds', () {
    test('a month either side of now is out of bounds', () {
      final now = DateTime.now();

      expect(
        TimesState.isWithinBounds(DateTime(now.year, now.month - 13)),
        isFalse,
      );
      expect(
        TimesState.isWithinBounds(DateTime(now.year, now.month + 13)),
        isFalse,
      );
    });

    test('a year either side of now is in bounds', () {
      final now = DateTime.now();

      expect(
        TimesState.isWithinBounds(DateTime(now.year, now.month - 12)),
        isTrue,
      );
      expect(
        TimesState.isWithinBounds(DateTime(now.year, now.month + 12)),
        isTrue,
      );
    });

    test('bounds compare by month, not by day', () {
      // The first day of the earliest month is in bounds even though `now` is
      // later in that same month — otherwise the current month would have to be
      // reached through the picker every time.
      expect(TimesState.isWithinBounds(TimesState.earliestMonth), isTrue);
      expect(TimesState.isWithinBounds(TimesState.latestMonth), isTrue);
    });

    test('stepping is bounded at both ends', () {
      final state = TimesState(
        month: TimesState.earliestMonth,
        isLoading: false,
        days: const [],
      );
      expect(state.canStepBack, isFalse);
      expect(state.canStepForward, isTrue);

      final last = TimesState(
        month: TimesState.latestMonth,
        isLoading: false,
        days: const [],
      );
      expect(last.canStepForward, isFalse);
      expect(last.canStepBack, isTrue);
    });

    test('the current month is recognised as current', () {
      final now = DateTime.now();
      expect(
        TimesState(
          month: DateTime(now.year, now.month),
          days: const [],
        ).isCurrentMonth,
        isTrue,
      );
      expect(
        TimesState(
          month: DateTime(now.year, now.month + 1),
          days: const [],
        ).isCurrentMonth,
        isFalse,
      );
    });
  });
}
