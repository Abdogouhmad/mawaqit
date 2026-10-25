import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Opens a year-and-month sheet scoped to the same range the chevrons allow.
///
/// `MonthPicker` is private in Material, so the twelve months are laid out here.
/// That turns out to be an opportunity rather than a workaround: a twelve-cell
/// grid shows the whole year at once, so the bounds are visible in the shape of
/// the grid itself — the first and last rows greyed — instead of being a rule the
/// user only discovers by pressing a chevron and having nothing happen.
///
/// Invoked from the almanac masthead, whose month name is the control.
Future<void> showMonthPickerSheet(
  BuildContext context, {
  required DateTime selected,
  required ValueChanged<DateTime> onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => _MonthPickerSheet(
    selected: selected,
    onSelected: (month) {
      // Pop first, then commit. The reverse order would rebuild the month behind
      // a closing sheet and leave the previous month's rows on screen for the
      // duration of the dismissal animation.
      Navigator.of(sheetContext).pop();
      onSelected(month);
    },
  ),
);

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late DateTime _viewing = DateTime(widget.selected.year);

  int get _year => _viewing.year;

  bool get _canStepBack =>
      !DateTime(_year - 1).isBefore(TimesState.earliestMonth);

  bool get _canStepForward =>
      !DateTime(_year + 1).isAfter(TimesState.latestMonth);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final earliest = TimesState.earliestMonth;
    final latest = TimesState.latestMonth;

    // Built from DateFormat rather than a constant list so the sheet shows
    // "März" and "أكتوبر" instead of English month names — the grid is the whole
    // content of this sheet, so its language is the sheet. One formatter, reused
    // for all twelve cells.
    final monthFormat = DateFormat.MMM(locale);
    final monthNames = [
      for (var m = 1; m <= 12; m++)
        monthFormat.format(DateTime(2024, m)),
    ];
    final yearLabel = DateFormat.y(locale).format(_viewing);

    bool withinBounds(int month) {
      final candidate = DateTime(_year, month);
      return !candidate.isBefore(earliest) && !candidate.isAfter(latest);
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = rtl ? Icons.chevron_right : Icons.chevron_left;
    final forwardIcon = rtl ? Icons.chevron_left : Icons.chevron_right;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.huge,
          0,
          AppSpacing.huge,
          AppSpacing.giga,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: UiText(
                      yearLabel,
                      type: UiTextType.headlineSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(backIcon),
                  onPressed: _canStepBack
                      ? () => setState(() => _viewing = DateTime(_year - 1))
                      : null,
                  tooltip: MaterialLocalizations.of(context)
                      .previousMonthTooltip,
                ),
                IconButton(
                  icon: Icon(forwardIcon),
                  onPressed: _canStepForward
                      ? () => setState(() => _viewing = DateTime(_year + 1))
                      : null,
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.4,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    name: monthNames[m - 1],
                    selected:
                        widget.selected.year == _year &&
                        widget.selected.month == m,
                    isCurrentMonth: now.year == _year && now.month == m,
                    enabled: withinBounds(m),
                    onPressed: () => widget.onSelected(DateTime(_year, m)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.giga),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () =>
                    widget.onSelected(DateTime(now.year, now.month)),
                child: Text(l10n.timesHighlightedToday),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.name,
    required this.selected,
    required this.isCurrentMonth,
    required this.enabled,
    required this.onPressed,
  });

  final String name;
  final bool selected;
  final bool isCurrentMonth;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Selected is the app's primary, current-but-not-selected is an outline, and
    // everything else is a plain tonal chip. Three clearly different treatments,
    // so "which month am I on" and "which month is today" never have to be told
    // apart from a shape alone.
    final (background, foreground, border) = selected
        ? (scheme.primary, scheme.onPrimary, null)
        : enabled
        ? (
            isCurrentMonth
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerLow,
            scheme.onSurface,
            isCurrentMonth ? scheme.primary : scheme.outlineVariant,
          )
        : (scheme.surfaceContainerLow, scheme.onSurfaceVariant, null);

    return Material(
      color: enabled
          ? background
          : scheme.surfaceContainerLow.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border == null ? null : Border.all(color: border),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: UiText(
            name,
            type: UiTextType.labelLarge,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: enabled
                ? foreground
                : scheme.onSurfaceVariant.withValues(alpha: 0.38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
