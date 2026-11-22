import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/features/times/widgets/prayer_grid.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// How each prayer's time moves across the displayed month, in whole minutes.
///
/// One quiet card answers the question a day-by-day table structurally cannot:
/// does Isha get earlier or later this month? The list below stays responsible
/// for "what time is it on the 20th"; nothing here repeats a row.
class MonthShiftCard extends StatelessWidget {
  const MonthShiftCard({super.key, required this.shifts});

  final List<TimesShift> shifts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final digits = NumberFormat.decimalPattern(locale);

    return AppCard(
      ambient: false,
      color: scheme.surfaceContainerLow,
      borderColor: scheme.outlineVariant,
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiText(
            l10n.timesMonthShift,
            type: UiTextType.labelSmall,
            fontWeight: AppWeight.bold,
            letterSpacing: AppTypeDetail.sectionLetterSpacing,
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
            color: scheme.onSurfaceVariant.withValues(
              alpha: AppOpacity.secondaryText,
            ),
            letterSpacing: AppTypeDetail.fineTracking,
            fontWeight: AppWeight.regular,
          ),
        ],
      ),
    );
  }
}

/// One cell per prayer, measured from the widest localized label so a long name
/// wraps inside its own cell instead of pushing the figures off the card.
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

    // Tertiary is the app's solar fact colour, shared with the arc. A drift is
    // not a warning, so it must not borrow the action colour.
    final accent = shift.minutes == 0
        ? scheme.onSurfaceVariant.withValues(alpha: AppOpacity.faintMark)
        : scheme.tertiary;
    final magnitude = digits.format(shift.minutes.abs());

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
            fontWeight: AppWeight.semibold,
            letterSpacing: AppTypeDetail.fineTracking,
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
                  fontWeight: AppWeight.bold,
                  color: accent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  letterSpacing: AppTypeDetail.untacked,
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
