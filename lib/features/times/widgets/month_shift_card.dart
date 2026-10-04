import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/features/times/widgets/prayer_grid.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// How each prayer's time moves across the displayed month, in whole minutes.
///
/// This is the one thing a day-by-day month view structurally cannot show. The
/// question "does Isha get earlier or later this month" is answered by comparing
/// two cells nineteen rows apart, and the old five-column table answered it by
/// rendering those cells about 5dp tall — at which point a two-minute difference
/// between weeks is not readable at all.
///
/// So the comparison moves up into a summary, where there is room to render it,
/// and the list below is left to answer "what time is it on the 20th". Two
/// elements, one job each: this card is the month's shape, the list is any single
/// day. Nothing below repeats a number from up here, and nothing up here
/// duplicates a row.
class MonthShiftCard extends StatelessWidget {
  const MonthShiftCard({super.key, required this.shifts});

  /// Signed per-prayer drift, already validated by [TimesState.shifts].
  final List<TimesShift> shifts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Locale-aware digits. `intl` gives Arabic-Indic numerals for `ar`, which
    // is both correct and about 12% narrower — the grid measurement above and
    // the value rendered here therefore agree.
    final digits = NumberFormat.decimalPattern(locale);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiText(
            l10n.timesMonthShift,
            type: UiTextType.labelSmall,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) => _ShiftRow(
              shifts: shifts,
              digits: digits,
              availableWidth: constraints.maxWidth,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          UiText(
            l10n.timesShiftCaption,
            type: UiTextType.labelSmall,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            letterSpacing: 0.1,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}

/// One cell per prayer: the localized name over the signed minute change.
///
/// Laid out as a [Wrap] of fixed-width cells rather than a [Row] of five
/// [Expanded]s, because five evenly divided columns stop being five columns the
/// moment one label is too wide: the labels and the numbers would no longer sit
/// over each other, which is the only reason for drawing them in a grid at all.
class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shifts,
    required this.digits,
    required this.availableWidth,
  });

  final List<TimesShift> shifts;
  final NumberFormat digits;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final textTheme = Theme.of(context).textTheme;

    // The cell is as wide as the widest label actually needs, capped at an even
    // share of the row so a long localized name wraps its own cell instead of
    // pushing the numbers off the card.
    final labelStyle = textTheme.labelMedium ?? const TextStyle();
    final direction = Directionality.of(context);
    final widestLabel = shifts
        .map(
          (s) => PrayerGrid.measure(
            s.kind.localized(l10n),
            labelStyle,
            textScaler,
            direction: direction,
          ),
        )
        .fold<double>(0, (a, b) => a > b ? a : b);
    final evenShare = availableWidth / shifts.length;
    final cellWidth = widestLabel > evenShare ? evenShare : widestLabel;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        for (final shift in shifts)
          SizedBox(
            width: cellWidth,
            child: _ShiftCell(
              shift: shift,
              digits: digits,
              unit: l10n.unitMinutes,
            ),
          ),
      ],
    );
  }
}

class _ShiftCell extends StatelessWidget {
  const _ShiftCell({
    required this.shift,
    required this.digits,
    required this.unit,
  });

  final TimesShift shift;
  final NumberFormat digits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final name = shift.kind.localized(l10n);

    final (icon, direction) = switch (shift.minutes) {
      final m when m > 0 => (Icons.arrow_upward, l10n.timesShiftLater),
      final m when m < 0 => (Icons.arrow_downward, l10n.timesShiftEarlier),
      _ => (Icons.remove, l10n.timesShiftUnchanged),
    };

    // Gold, not the brand primary. A drift is a fact about the sky, not an
    // action, and colouring it with the app's action colour would make the card
    // read as a set of warnings. Tertiary is already the app's colour for solar
    // facts, so this is consistent with the sunrise card rather than a new idea.
    final accent = shift.minutes == 0
        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
        : scheme.tertiary;

    final magnitude = digits.format(shift.minutes.abs());

    // One label for the cell, in the order a person would say it: the prayer,
    // the number, then the direction. The icon carries the direction visually
    // and is meaningless without it announced.
    return Semantics(
      label: '$name, $magnitude$unit $direction',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UiText(
            name,
            type: UiTextType.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            // `labelSmall` is the app's tracked uppercase-ish style; the shift
            // value below is set in it too so the two read as one figure.
            letterSpacing: 0.3,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.xs, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: UiText(
                  '$magnitude$unit',
                  type: UiTextType.labelMedium,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Same reason the grid strips tracking: these are figures in a
                  // column and they are meant to line up.
                  letterSpacing: 0,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
