import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:mawaqit/core/ui/theme/text_theme.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/utils/hijri_dates.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/times/widgets/prayer_grid.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// One day of the month: who it is, and the five times.
///
/// Every day uses the same [PrayerGrid], so the columns line up down the whole
/// month — the property the screen depends on. What changed from the old table
/// is the number of columns that grid holds: it is however many the times can be
/// rendered in *at full size*, rather than always five with each cell shrunk to
/// fit.
class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.day,
    required this.isToday,
    required this.grid,
    required this.nextPrayer,
    required this.locale,
    required this.now,
  });

  final PrayerDay day;

  /// Whether this is today. Drives the row's filled treatment and the filled
  /// day-number disc.
  final bool isToday;

  /// Shared by every row in the month so the columns stay aligned.
  final PrayerGrid grid;

  /// The prayer still to come today, or `null` once the day is over.
  ///
  /// Only ever non-null for today's row. Passed prayers are dimmed and this one is
  /// picked out in the brand colour, which turns a list of numbers into a
  /// statement about where the user is in their day without spending a separate
  /// row of chrome on it.
  final PrayerKind? nextPrayer;

  final String locale;

  /// One instant for the whole month, read by the screen once.
  ///
  /// Not read per row: 31 rows each calling `DateTime.now()` is 31 chances to
  /// disagree with each other across a midnight boundary, and a row that thinks
  /// it is still in the future would keep showing a prayer as "upcoming" after
  /// the row above it had already marked the same time as passed.
  final DateTime now;

  /// Height one row occupies, from the theme and the grid rather than measured.
  ///
  /// Rows are uniform, so this is what lets the screen open the month *on today*
  /// with arithmetic instead of guessing: the row for day *n* starts at
  /// `n * heightFor(...)`. Slightly approximate — the day line can exceed the disc
  /// on large text — but out by a row at worst, which is invisible.
  static double heightFor(
    PrayerGrid grid,
    TextTheme textTheme,
    TextScaler scaler, {
    int prayerCount = 5,
  }) {
    double line(TextStyle? style, double fallback) => AppTextTheme.lineHeight(
      style ?? TextStyle(fontSize: fallback, height: 1.3),
      scaler,
    );

    return
    // The row's own vertical padding.
    AppSpacing.lg * 2 +
        // The day line: the taller of the disc and the weekday name.
        math.max(
          AppSpacing.blockLg,
          line(textTheme.titleSmall, AppFontSize.xl),
        ) +
        AppSpacing.md +
        // Each strip: label, gap, time, then its own trailing gap.
        grid.stripsFor(prayerCount) *
            (line(textTheme.labelSmall, AppFontSize.xs) +
                AppSpacing.xxs +
                line(grid.timeStyle, AppFontSize.md) +
                AppSpacing.sm) +
        // The margin separating it from the next day.
        AppSpacing.md;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final spoken = <String>[
      DateFormat.EEEE(locale).format(day.date),
      DateFormat.MMMEd(locale).format(day.date),
      if (isToday) l10n.timesHighlightedToday,
      for (final prayer in day.prayers)
        '${prayer.kind.localized(l10n)} ${TimeFormatter.clock(prayer.time)}',
    ].join(', ');

    return Semantics(
      label: spoken,
      // The children are decorative here: their content is already in the label.
      excludeSemantics: true,
      child: Container(
        // One device marks today — a filled shape. The old row used three at once
        // (tinted fill, outline, and a leading accent bar that had to be reserved
        // on every row so today's columns did not sit 3dp out of line with the
        // rest). A fill alone is findable in a column of quiet rows and costs the
        // neighbours nothing.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isToday ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayLine(day: day, isToday: isToday, locale: locale),
            const SizedBox(height: AppSpacing.md),
            for (
              var start = 0;
              start < day.prayers.length;
              start += grid.columns
            )
              _PrayerStrip(
                prayers: day.prayers.sublist(
                  start,
                  (start + grid.columns).clamp(0, day.prayers.length),
                ),
                grid: grid,
                isToday: isToday,
                now: now,
                nextPrayer: nextPrayer,
              ),
          ],
        ),
      ),
    );
  }
}

/// The weekday, the Gregorian day number and the Hijri day, on one line.
///
/// Weekday first because it is what makes a monthly table usable: without it the
/// rows are 31 interchangeable numbers and "which of these are Fridays" has no
/// answer. It gets the whole line here, spelled out — the old table had to
/// abbreviate it to fit beside five times, and in Arabic `DateFormat.E` has no
/// abbreviated form at all, so the measurement there was clipping the date on
/// every row.
class _DayLine extends StatelessWidget {
  const _DayLine({
    required this.day,
    required this.isToday,
    required this.locale,
  });

  final PrayerDay day;
  final bool isToday;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final weekday = DateFormat.EEEE(locale).format(day.date);
    final hijriDay = HijriDates.dayOfMonth(day.date);

    return Row(
      children: [
        // The disc is the month's alignment anchor: it sits in the same place on
        // every row, so the eye can find a date without reading the number, and
        // it is where "today" is marked.
        Container(
          width: AppSpacing.blockLg,
          height: AppSpacing.blockLg,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? scheme.primary : Colors.transparent,
          ),
          child: UiText(
            '${day.date.day}',
            type: UiTextType.labelLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: isToday ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: UiText(
            weekday,
            type: UiTextType.titleSmall,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: isToday ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Umm al-Qura day, from feat.md §10. Muted and small so the Gregorian
        // date stays dominant, but present on every row because the Gregorian
        // month routinely straddles a Hijri one and the app's primary audience
        // works from the Hijri side.
        UiText(
          '$hijriDay',
          type: UiTextType.labelSmall,
          color: (isToday ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
              .withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ],
    );
  }
}

/// One row of prayer columns: the localized names over their times.
///
/// The cells are [Expanded], so they are equal by construction and cannot drift
/// out of alignment with the pinned header above. Times are additionally
/// allowed to scale down, but only because [PrayerGrid.resolve] has already
/// chosen the type size it measured as fitting — so this is a backstop for a
/// string wider than the one it measured against, never the mechanism that keeps
/// the grid on screen.
class _PrayerStrip extends StatelessWidget {
  const _PrayerStrip({
    required this.prayers,
    required this.grid,
    required this.isToday,
    required this.now,
    required this.nextPrayer,
  });

  final List<PrayerTime> prayers;
  final PrayerGrid grid;
  final bool isToday;
  final DateTime now;
  final PrayerKind? nextPrayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < grid.columns; i++) ...[
            if (i > 0) const SizedBox(width: PrayerGrid.columnGap),
            Expanded(
              child: i < prayers.length
                  ? _PrayerCell(
                      prayer: prayers[i],
                      style: grid.timeStyle,
                      isToday: isToday,
                      now: now,
                      nextPrayer: nextPrayer,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({
    required this.prayer,
    required this.style,
    required this.isToday,
    required this.now,
    required this.nextPrayer,
  });

  final PrayerTime prayer;
  final TextStyle? style;
  final bool isToday;
  final DateTime now;
  final PrayerKind? nextPrayer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final isNext = isToday && nextPrayer == prayer.kind;
    final hasPassed = prayer.time.isBefore(now);

    // Only today's row says anything about passed and upcoming; on any other day
    // the times are simply the times, and dimming them by the current clock would
    // say "already gone" about next Tuesday.
    final muted = isToday && hasPassed;
    final color = isNext
        ? scheme.primary
        : muted
        ? (isToday ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
              .withValues(alpha: 0.55)
        : isToday
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          prayer.kind.localized(l10n),
          type: UiTextType.labelSmall,
          fontWeight: FontWeight.w600,
          // Tracking off: the label sits directly over a fixed-width time, and a
          // tracked label next to an untracked number reads as two different
          // settings rather than one column.
          letterSpacing: 0.2,
          color: color.withValues(alpha: muted ? 0.7 : 0.85),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            TimeFormatter.clock(prayer.time),
            maxLines: 1,
            style: style?.copyWith(
              color: color,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
