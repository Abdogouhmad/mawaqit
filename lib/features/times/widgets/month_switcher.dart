import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The month control: a tonal pill that opens a month picker, flanked by paging
/// chevrons, with a way back to the current month when you are not in it.
///
/// This replaces a row of three bare icon buttons and a decorative dot. The dot
/// was the *only* indication of which month you were looking at beyond the title
/// text, and the only route home from a paged month was counting chevrons back
/// one at a time. The pill makes the month itself the control, so the header is
/// tappable and the sheet it opens lands on a year *and* a month — the distance
/// from "October" to "next March" goes from five taps to two.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key, required this.state});

  final TimesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat.yMMMM(locale).format(state.month);

    // A chevron points *backwards* in reading order, so the glyph has to swap
    // with the locale. Material's chevrons are not auto-mirrored, so the pair is
    // chosen explicitly rather than relying on a direction-aware `Icon`.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = rtl ? Icons.chevron_right : Icons.chevron_left;
    final forwardIcon = rtl ? Icons.chevron_left : Icons.chevron_right;

    void step(int delta) =>
        ref.read(timesControllerProvider.notifier).step(delta);

    return Row(
      children: [
        _PageButton(
          icon: backIcon,
          tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
          onPressed: state.canStepBack ? () => step(-1) : null,
        ),
        // Filled tonal rather than bare text: the month is the one thing on this
        // screen that is both a label and a control, and it should look like one.
        // `Expanded` because at 200% text a long localized month name ("September",
        // "أكتوبر", "septembre") plus the Today pill has to have somewhere to give.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.center,
            child: _MonthPill(
              label: label,
              tooltip: l10n.timesSelectMonth,
              onPressed: () => showMonthPickerSheet(
                context,
                selected: state.month,
                onSelected: (month) =>
                    ref.read(timesControllerProvider.notifier).goToMonth(month),
              ),
            ),
          ),
        ),
        _PageButton(
          icon: forwardIcon,
          tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
          onPressed: state.canStepForward ? () => step(1) : null,
        ),
        // Present only when there is somewhere to go back to. A permanently
        // reserved slot with a dot in it was the previous arrangement, and the
        // dot carried no information the title did not already carry.
        if (!state.isCurrentMonth)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
            child: _TodayPill(
              label: l10n.timesHighlightedToday,
              onPressed: () =>
                  ref.read(timesControllerProvider.notifier).goToCurrentMonth(),
            ),
          ),
      ],
    );
  }
}

/// 48dp round paging control.
///
/// Sized by its slot rather than by its glyph: an icon-only control laid out at
/// its visual box lands near 30dp, under the 48dp minimum target feat.md §6 sets,
/// and paging back a year is a repeated gesture.
class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    onPressed: onPressed,
    tooltip: tooltip,
    // 48 rather than the icon button default: these sit either side of the month
    // pill and the default's 40dp visually crowds it.
    constraints: const BoxConstraints.tightFor(
      width: AppSpacing.touch,
      height: AppSpacing.touch,
    ),
  );
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: UiText(
                    label,
                    type: UiTextType.titleSmall,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.expand_more,
                  size: AppIconSize.lg,
                  color: scheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.timesJumpToToday,
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: UiText(
              label,
              type: UiTextType.labelMedium,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a year-and-month sheet scoped to the same range the chevrons allow.
///
/// `MonthPicker` is private in Material, so the twelve months are laid out here.
/// That turns out to be an opportunity rather than a workaround: a twelve-cell
/// grid shows the whole year at once, so the bounds are visible in the shape of
/// the grid itself — the first and last rows greyed — instead of being a rule the
/// user only discovers by pressing a chevron and having nothing happen.
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
      !DateTime(_year - 1, 1).isBefore(TimesState.earliestMonth);

  bool get _canStepForward =>
      !DateTime(_year + 1, 1).isAfter(TimesState.latestMonth);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    // Built from DateFormat rather than a constant list so the sheet shows
    // "März" and "أكتوبر" instead of English month names — the grid is the whole
    // content of this sheet, so its language is the sheet.
    final monthNames = [
      for (var m = 1; m <= 12; m++)
        DateFormat.MMM(locale).format(DateTime(2024, m)),
    ];

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
                      DateFormat.y(locale).format(_viewing),
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
                    enabled: TimesState.isWithinBounds(DateTime(_year, m)),
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
