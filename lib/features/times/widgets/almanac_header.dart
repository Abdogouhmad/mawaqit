import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/utils/hijri_dates.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/features/times/widgets/month_switcher.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The Times tab's masthead: where, which month, and where that month sits in
/// the Hijri calendar.
///
/// It replaces the previous pair of a title block *and* a month control, which
/// printed the month twice about 50dp apart. Here the month name *is* the
/// control — tapping it opens the year-and-month picker — with the paging
/// chevrons hugging it and the today shortcut appearing only once you have
/// paged away.
///
/// Three lines, top to bottom: a quiet location eyebrow, the large month and
/// year, and the Hijri span the month covers. The span is the part a Gregorian
/// month view cannot state for itself, and it is the line the app's audience
/// actually schedules by.
class AlmanacHeader extends ConsumerWidget {
  const AlmanacHeader({super.key, required this.state});

  final TimesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final monthName = DateFormat.MMMM(locale).format(state.month);
    final year = DateFormat.y(locale).format(state.month);

    // A chevron points *backwards* in reading order, so the glyph swaps with the
    // locale. Material's chevrons do not auto-mirror.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = rtl ? Icons.chevron_right : Icons.chevron_left;
    final forwardIcon = rtl ? Icons.chevron_left : Icons.chevron_right;

    final monthStyle = textTheme.headlineMedium!.copyWith(
      // Light, per the brand's display-weight rule; the theme's own tracking is
      // kept so Arabic still resolves to zero.
      fontWeight: FontWeight.w300,
    );
    final yearStyle = textTheme.titleSmall!.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: AppIconSize.sm,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: UiText(
                state.locationName.isEmpty
                    ? l10n.timesSubtitle
                    : state.locationName,
                type: UiTextType.labelSmall,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!state.isCurrentMonth)
              _TodayPill(
                label: l10n.timesHighlightedToday,
                onPressed: () => ref
                    .read(timesControllerProvider.notifier)
                    .goToCurrentMonth(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _PageButton(
              icon: backIcon,
              tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
              onPressed: state.canStepBack
                  ? () => ref.read(timesControllerProvider.notifier).step(-1)
                  : null,
            ),
            Expanded(
              child: _MonthTitle(
                monthName: monthName,
                year: year,
                monthStyle: monthStyle,
                yearStyle: yearStyle,
                tooltip: l10n.timesSelectMonth,
                onPressed: () => showMonthPickerSheet(
                  context,
                  selected: state.month,
                  onSelected: (month) => ref
                      .read(timesControllerProvider.notifier)
                      .goToMonth(month),
                ),
              ),
            ),
            _PageButton(
              icon: forwardIcon,
              tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
              onPressed: state.canStepForward
                  ? () => ref.read(timesControllerProvider.notifier).step(1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        UiText(
          _hijriSpan(state),
          type: UiTextType.labelMedium,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// The Hijri month (or months) the displayed Gregorian month falls in.
  ///
  /// A Gregorian month routinely straddles a Hijri one — most of all around
  /// Ramadan and Dhu al-Hijjah — so both sides are named when they differ.
  static String _hijriSpan(TimesState state) {
    if (state.days.isEmpty) return TimeFormatter.hijriMonth(state.month);
    final first = state.days.first.date;
    final last = state.days.last.date;
    final start = TimeFormatter.hijriMonth(first);
    if (HijriDates.isSameHijriMonth(first, last)) return start;
    return '$start – ${TimeFormatter.hijriMonth(last)}';
  }
}

/// The month name and year, centred, tappable to open the picker.
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({
    required this.monthName,
    required this.year,
    required this.monthStyle,
    required this.yearStyle,
    required this.tooltip,
    required this.onPressed,
  });

  final String monthName;
  final String year;
  final TextStyle monthStyle;
  final TextStyle yearStyle;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: monthName, style: monthStyle),
                  TextSpan(text: '  ', style: monthStyle),
                  TextSpan(text: year, style: yearStyle),
                ],
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: monthStyle.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// 48dp round paging control, matching the picker sheet's own arrows.
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
    constraints: const BoxConstraints.tightFor(
      width: AppSpacing.touch,
      height: AppSpacing.touch,
    ),
  );
}

/// The shortcut home, shown only when the masthead has paged away from today.
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
              vertical: AppSpacing.sm,
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
