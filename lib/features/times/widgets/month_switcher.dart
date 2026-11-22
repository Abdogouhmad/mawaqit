import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Opens a year-and-month sheet scoped to the same range the chevrons allow.
///
/// `MonthPicker` is private in Material, so the twelve months are laid out here.
/// A twelve-cell grid shows the whole year at once and lets `Directionality`
/// place January on the reading-start edge in both LTR and RTL.
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
      // Pop first, then commit: rebuilding behind a closing sheet leaves the
      // previous month's rows on screen for the duration of the dismissal.
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

    final monthFormat = DateFormat.MMM(locale);
    final monthNames = [
      for (var m = 1; m <= 12; m++) monthFormat.format(DateTime(2024, m)),
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
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.huge,
          AppSize.zero,
          AppSpacing.huge,
          AppSpacing.giga,
        ),
        // The sheet is capped at 70% of the screen. At 2x text a twelve-month
        // grid plus the year controls is taller than that, so it scrolls instead
        // of being clipped at the bottom.
        child: SingleChildScrollView(
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
                        fontWeight: AppWeight.semibold,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: backIcon,
                    tooltip: MaterialLocalizations.of(context)
                        .previousMonthTooltip,
                    onPressed: _canStepBack
                        ? () => setState(() => _viewing = DateTime(_year - 1))
                        : null,
                  ),
                  AppIconButton(
                    icon: forwardIcon,
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                    onPressed: _canStepForward
                        ? () => setState(() => _viewing = DateTime(_year + 1))
                        : null,
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
              AppButton(
                label: l10n.timesHighlightedToday,
                icon: Icons.today_outlined,
                variant: AppButtonVariant.text,
                onPressed: () =>
                    widget.onSelected(DateTime(now.year, now.month)),
              ),
            ],
          ),
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

    // Selected is the app's primary, current-but-not-selected is outlined, and
    // unavailable months are a faint tonal chip. Three distinct treatments so
    // "which month am I on" and "which month is today" never need explaining.
    final (background, foreground, border) = selected
        ? (scheme.primary, scheme.onPrimary, null)
        : enabled
        ? (
            isCurrentMonth
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerLow,
            scheme.onSurface,
            isCurrentMonth ? scheme.primary : null,
          )
        : (
            scheme.surfaceContainerLow.withValues(alpha: AppOpacity.faintMark),
            scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled),
            null,
          );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: AppPill(
        label: name,
        backgroundColor: background,
        foregroundColor: foreground,
        borderColor: border,
        onTap: enabled ? onPressed : null,
        expanded: true,
        dense: true,
        letterSpacing: AppTypeDetail.labelTracking,
      ),
    );
  }
}
