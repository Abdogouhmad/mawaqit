import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:mawaqit/core/calendar/hijri_calendar_data.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// A quiet, paged Hijri month with today and well-known events called out.
///
/// Lives on the Times tab rather than in a new tab: the month table above and
/// the Hijri view below are two readings of the same date range, and splitting
/// them would leave the user paging one while wondering about the other.
class HijriCalendarCard extends StatefulWidget {
  const HijriCalendarCard({super.key, required this.today});

  final DateTime today;

  @override
  State<HijriCalendarCard> createState() => _HijriCalendarCardState();
}

class _HijriCalendarCardState extends State<HijriCalendarCard> {
  late int _year;
  late int _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final current = HijriCalendarData.monthOf(widget.today);
    _year = current.year;
    _month = current.month;
    _selected = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
  }

  void _step(int delta) {
    final next = delta > 0
        ? HijriCalendarData.next(_year, _month)
        : HijriCalendarData.previous(_year, _month);
    if (next.year < HijriCalendarData.minYear ||
        next.year > HijriCalendarData.maxYear) {
      return;
    }
    setState(() {
      _year = next.year;
      _month = next.month;
    });
  }

  void _goToday() {
    final current = HijriCalendarData.monthOf(widget.today);
    setState(() {
      _year = current.year;
      _month = current.month;
      _selected = DateTime(
        widget.today.year,
        widget.today.month,
        widget.today.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final view = HijriCalendarData.month(_year, _month);
    final digits = NumberFormat.decimalPattern(locale);
    final rtl = Directionality.of(context) == TextDirection.rtl;

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
          Row(
            children: [
              Expanded(
                child: UiText(
                  l10n.calendarTitle,
                  type: UiTextType.labelSmall,
                  fontWeight: AppWeight.bold,
                  letterSpacing: AppTypeDetail.sectionLetterSpacing,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (_year != HijriCalendarData.monthOf(widget.today).year ||
                  _month != HijriCalendarData.monthOf(widget.today).month)
                AppPill(
                  label: l10n.calendarToday,
                  onTap: _goToday,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppIconButton(
                icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                tooltip: l10n.calendarPreviousMonth,
                onPressed: _year > HijriCalendarData.minYear || _month > 1
                    ? () => _step(-1)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: UiText(
                    TimeFormatter.hijriMonth(view.firstDay),
                    type: UiTextType.titleSmall,
                    fontWeight: AppWeight.semibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              AppIconButton(
                icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                tooltip: l10n.calendarNextMonth,
                onPressed: _year < HijriCalendarData.maxYear || _month < 12
                    ? () => _step(1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _WeekHeader(locale: locale),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) => _DayGrid(
              view: view,
              selected: _selected,
              today: widget.today,
              digits: digits,
              l10n: l10n,
              availableWidth: constraints.maxWidth,
              onSelect: (day) => setState(() {
                _selected = view.gregorian(day);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectedDay(
            selected: _selected,
            view: view,
            l10n: l10n,
            locale: locale,
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = DateFormat.E(locale);
    // 2024-01-01 is a Monday, so the seven days from it are Monday-first.
    final monday = DateTime(2024);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: UiText(
                formatter.format(monday.add(Duration(days: i))),
                type: UiTextType.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppOpacity.secondaryText,
                ),
                fontWeight: AppWeight.semibold,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.view,
    required this.selected,
    required this.today,
    required this.digits,
    required this.l10n,
    required this.availableWidth,
    required this.onSelect,
  });

  final HijriMonthView view;
  final DateTime selected;
  final DateTime today;
  final NumberFormat digits;
  final AppLocalizations l10n;
  final double availableWidth;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cellWidth = availableWidth / 7;
    final cells = <Widget>[
      for (var i = 0; i < view.leadingBlanks; i++)
        SizedBox(width: cellWidth, height: AppSpacing.touch),
      for (var day = 1; day <= view.dayCount; day++)
        SizedBox(
          width: cellWidth,
          height: AppSpacing.touch,
          child: _DayCell(
            day: day,
            date: view.gregorian(day),
            view: view,
            digits: digits,
            isSelected: _sameDay(view.gregorian(day), selected),
            isToday: _sameDay(view.gregorian(day), today),
            onSelect: () => onSelect(day),
          ),
        ),
    ];

    return Wrap(children: cells);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.view,
    required this.digits,
    required this.isSelected,
    required this.isToday,
    required this.onSelect,
  });

  final int day;
  final DateTime date;
  final HijriMonthView view;
  final NumberFormat digits;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final event = view.eventOn(day);
    final label = event == null
        ? digits.format(day)
        : '${digits.format(day)}, ${_eventLabel(event, AppLocalizations.of(context))}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Center(
          child: Container(
            width: AppSpacing.control,
            height: AppSpacing.control,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? scheme.primary
                  : isToday
                  ? scheme.primary.withValues(alpha: AppOpacity.accent)
                  : null,
            ),
            child: Center(
              child: UiText(
                digits.format(day),
                type: UiTextType.labelSmall,
                color: isSelected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: isToday || isSelected
                    ? AppWeight.bold
                    : AppWeight.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _eventLabel(HijriEvent event, AppLocalizations l10n) =>
      switch (event) {
        HijriEvent.newYear => l10n.hijriEventNewYear,
        HijriEvent.mawlid => l10n.hijriEventMawlid,
        HijriEvent.ramadan => l10n.hijriEventRamadan,
        HijriEvent.eidAlFitr => l10n.hijriEventEidAlFitr,
        HijriEvent.eidAlAdha => l10n.hijriEventEidAlAdha,
      };
}

class _SelectedDay extends StatelessWidget {
  const _SelectedDay({
    required this.selected,
    required this.view,
    required this.l10n,
    required this.locale,
  });

  final DateTime selected;
  final HijriMonthView view;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gregorian = DateFormat.yMMMMd(locale).format(selected);
    final hijriText = TimeFormatter.hijri(selected);
    final events = <String>[
      for (final event in view.events)
        if (view.gregorian(event.day) == selected) _eventLabel(event, l10n),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiText(
          l10n.calendarEvents,
          type: UiTextType.labelSmall,
          fontWeight: AppWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xs),
        UiText(
          events.isEmpty ? l10n.calendarNoEvents : events.join(' · '),
          type: UiTextType.bodySmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        UiText(
          l10n.calendarGregorian(gregorian),
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant.withValues(
            alpha: AppOpacity.secondaryText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        UiText(
          l10n.calendarHijri(hijriText),
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant.withValues(
            alpha: AppOpacity.secondaryText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _eventLabel(HijriEvent event, AppLocalizations l10n) =>
      switch (event) {
        HijriEvent.newYear => l10n.hijriEventNewYear,
        HijriEvent.mawlid => l10n.hijriEventMawlid,
        HijriEvent.ramadan => l10n.hijriEventRamadan,
        HijriEvent.eidAlFitr => l10n.hijriEventEidAlFitr,
        HijriEvent.eidAlAdha => l10n.hijriEventEidAlAdha,
      };
}
