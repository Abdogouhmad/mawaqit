import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/ui/widgets/app_chrome.dart';
import 'package:mawaqit/core/ui/widgets/empty_state.dart';
import 'package:mawaqit/core/utils/time_formatter.dart';
import 'package:mawaqit/features/times/times_controller.dart';
import 'package:mawaqit/features/times/widgets/day_row.dart';
import 'package:mawaqit/features/times/widgets/month_shift_card.dart';
import 'package:mawaqit/features/times/widgets/month_switcher.dart';
import 'package:mawaqit/features/times/widgets/prayer_grid.dart';
import 'package:mawaqit/features/times/widgets/prayer_labels_header.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Horizontal margin shared by the header and every row.
///
/// Named rather than repeated so the pinned prayer labels and the values they
/// name cannot drift apart; they are laid out by two different widgets that only
/// agree if they are inset by the same number.
const double _inset = AppSpacing.huge;

/// The monthly prayer schedule (feat.md §10).
///
/// Three zones, each with one job:
///
///  * the title and location — what this is, and for where;
///  * [MonthShiftCard] — the shape of the month, i.e. how far each prayer moves;
///  * the day list under a pinned header — the exact times.
///
/// The last two are deliberately different in kind. The list is a working
/// reference: aligned, dense, scrollable, the thing a specific day is read off.
/// The card is one assertion about the whole month. That split exists because the
/// earlier design made the list do both jobs, and five times across a 360dp phone
/// only render them about 5dp tall — see [PrayerGrid] — which is far too small to
/// read a two-minute shift out of.
class TimesScreen extends ConsumerStatefulWidget {
  const TimesScreen({super.key});

  @override
  ConsumerState<TimesScreen> createState() => _TimesScreenState();
}

class _TimesScreenState extends ConsumerState<TimesScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Returned by `attachScroll`; must be called before the controller is
  /// disposed or the listener keeps a reference to this dead `State`.
  VoidCallback? _detachScroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-attached rather than attached once: the scope's `onChanged` is a
    // closure over the shell, and it changes when the shell rebuilds, so a
    // listener captured on the first pass would report into a stale shell.
    _detachScroll?.call();
    _detachScroll = NavVisibilityScope.attachScroll(context, _scrollController);
  }

  @override
  void dispose() {
    _detachScroll?.call();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(timesControllerProvider);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: async.when(
        // A month either computed or did not, and the computation is fast enough
        // that a spinner is honest.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Not `error.toString()`: a raw exception or a bare "Null check operator
        // used on a null value" is not something a user can act on, and it leaks
        // implementation detail into the UI.
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.homeErrorTitle,
          body: l10n.timesLoadFailed,
          // An explicit retry, not a pull. `EmptyState` is not scrollable, so a
          // gesture here would be a promise the view cannot keep — the copy used to
          // say "pull down to try again" and there was nothing to pull.
          action: FilledButton(
            onPressed: () => ref.invalidate(timesControllerProvider),
            child: Text(l10n.actionRetry),
          ),
        ),
        // `skipLoadingOnReload` so a settings change mid-month keeps the current
        // month on screen while it recomputes. Replacing 31 days with a spinner
        // because a calculation method changed reads as data loss.
        skipLoadingOnReload: true,
        data: (state) => _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, TimesState state) {
    // `hasLocation` is `days.isNotEmpty`, which is also briefly true while a
    // *month* is paging. `isLoading` is what tells the two apart, and conflating
    // them is why paging used to flash the "pick a location" state every time.
    if (state.isLoading && !state.hasLocation) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.hasLocation) {
      return const _NoLocation();
    }
    return _Month(
      key: ValueKey(state.month),
      state: state,
      controller: _scrollController,
    );
  }
}

class _NoLocation extends ConsumerWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.location_off_outlined,
      title: l10n.timesTitle,
      body: l10n.timesNoLocation,
      action: FilledButton(
        onPressed: () => context.go(AppRoutes.settings),
        child: Text(l10n.timesGoToSettings),
      ),
    );
  }
}

class _Month extends ConsumerStatefulWidget {
  const _Month({super.key, required this.state, required this.controller});

  final TimesState state;
  final ScrollController controller;

  @override
  ConsumerState<_Month> createState() => _MonthState();
}

class _MonthState extends ConsumerState<_Month> {
  /// The column layout, resolved once per month rather than once per row.
  ///
  /// Every row and the pinned header share this one value, which is the only
  /// reason the columns line up. Resolving it inside the row builders would
  /// measure text 31 times to produce 31 identical answers.
  ///
  /// Discarded whenever the dependencies it was derived from change — a rotation,
  /// a system text-scale change, a different palette — because a grid measured for
  /// a 360dp portrait phone is a grid that overflows a landscape one.
  PrayerGrid? _grid;

  /// Guards the one-time scroll to today, so a rebuild (theme change, pull to
  /// refresh) does not yank the user back down the month.
  bool _didRevealToday = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _grid = null;
  }

  @override
  void dispose() {
    _grid = null;
    super.dispose();
  }

  /// Opens the month on today rather than on the 1st.
  ///
  /// On the 20th, the 1st is nineteen rows above the fold — the user lands on a
  /// month of days that have already happened. Runs after layout because the row
  /// offsets do not exist until then, and is skipped when today is not in the
  /// displayed month.
  void _revealToday() {
    if (_didRevealToday) return;
    _didRevealToday = true;
    if (!widget.state.isCurrentMonth) return;
    if (!widget.controller.hasClients) return;

    final today = DateTime.now();
    final index = widget.state.days.indexWhere(
      (day) =>
          day.date.year == today.year &&
          day.date.month == today.month &&
          day.date.day == today.day,
    );
    if (index <= 0) return;

    // Rows are uniform, so the target is arithmetic rather than a measurement —
    // `RenderAbstractViewport.getOffsetToReveal` would need a laid-out child for
    // the row it wants, and on the first frame there is not one yet.
    final rowHeight = DayRow.heightFor(
      _grid ?? const PrayerGrid(columns: 5, timeStyle: null),
      Theme.of(context).textTheme,
      MediaQuery.textScalerOf(context),
    );
    final headerHeight = PrayerLabelsHeader.heightFor(
      _grid ?? const PrayerGrid(columns: 5, timeStyle: null),
      Theme.of(context).textTheme,
      MediaQuery.textScalerOf(context),
    );
    final target = (index * rowHeight - headerHeight).clamp(
      0.0,
      widget.controller.position.maxScrollExtent,
    );
    widget.controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    _grid ??= PrayerGrid.resolve(
      textTheme: theme.textTheme,
      // The width a strip actually gets is the screen minus the screen gutter and
      // [DayRow]'s own horizontal padding, because the sliver padding and the row
      // padding are applied independently. Resolving against the outer number
      // hands every column `2 * md / columns` more than it has, which at two
      // columns is 8dp — enough to silently re-introduce the shrink the grid was
      // built to avoid.
      availableWidth:
          MediaQuery.sizeOf(context).width - _inset * 2 - AppSpacing.md * 2,
      widestText: _widestText(state),
      textScaler: MediaQuery.textScalerOf(context),
      direction: Directionality.of(context),
    );
    final grid = _grid!;

    // Read once for the whole month rather than per row: 31 `DateTime.now()`
    // calls to decide which single row is today is 31 chances to disagree with
    // itself across a midnight boundary.
    final now = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) => _revealToday());

    return RefreshIndicator(
      // Recomputes the month rather than re-requesting the location, so a pull on
      // a slow connection costs a calculation and not a second GPS round trip.
      onRefresh: () async => ref.invalidate(timesControllerProvider),
      color: scheme.primary,
      child: CustomScrollView(
        controller: widget.controller,
        // So the pull works even when the month is short enough to fit on screen.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              _inset,
              AppSpacing.md,
              _inset,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScreenTitle(locationName: state.locationName),
                  const SizedBox(height: AppSpacing.xl),
                  MonthSwitcher(state: state),
                  if (state.shifts != null) ...[
                    const SizedBox(height: AppSpacing.giga),
                    MonthShiftCard(shifts: state.shifts!),
                  ],
                  const SizedBox(height: AppSpacing.giga),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PrayerHeaderDelegate(
              background: scheme.surface,
              hairline: scheme.outlineVariant,
              height: PrayerLabelsHeader.heightFor(
                grid,
                theme.textTheme,
                MediaQuery.textScalerOf(context),
              ),
              child: PrayerLabelsHeader(grid: grid),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              _inset,
              0,
              _inset,
              AppChrome.scrollBottomPadding(context),
            ),
            sliver: SliverList.builder(
              itemCount: state.days.length,
              itemBuilder: (context, index) {
                final day = state.days[index];
                return DayRow(
                  day: day,
                  isToday: _isSameDay(day.date, now),
                  grid: grid,
                  // Only ever non-null for today's row: [DayRow] ignores it
                  // elsewhere, so a stale value on a past or future day cannot
                  // light up the wrong cell.
                  nextPrayer: _isSameDay(day.date, now)
                      ? day.currentOrNextPrayer(now)?.kind
                      : null,
                  locale: locale,
                  now: now,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The longest clock string this month will draw.
  ///
  /// Chosen by glyph count rather than measured, because measuring needs a style
  /// and the style is what the grid is about to decide. Counting is the safe
  /// direction: a longer count can only make the grid more conservative.
  static String _widestText(TimesState state) {
    var widest = '';
    for (final day in state.days) {
      for (final prayer in day.prayers) {
        final text = TimeFormatter.clock(prayer.time);
        if (text.length > widest.length) widest = text;
      }
    }
    return widest.isEmpty ? '00:00' : widest;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// The tab title and the one piece of context the schedule depends on.
///
/// Location only. This used to carry the month as well, which put two copies of
/// "October 2026" about 50dp apart with only the lower one updating as you paged.
class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          l10n.timesTitle,
          type: UiTextType.headlineSmall,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        UiText(
          locationName.isEmpty ? l10n.timesSubtitle : locationName,
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
