import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/text_theme.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/data/models/prayer_time.dart';
import 'package:mawaqit/features/times/widgets/prayer_grid.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The prayer names, pinned above the month.
///
/// Needed because a 31-day list scrolls the names away, and once they are gone
/// the columns are bare numbers again. It is built from the same [PrayerGrid] as
/// every [DayRow], so the labels sit exactly over their values — if the grid
/// resolved to three columns, this shows three columns in the same arrangement,
/// ragged last strip included.
class PrayerLabelsHeader extends StatelessWidget {
  const PrayerLabelsHeader({super.key, required this.grid});

  final PrayerGrid grid;

  /// Vertical space [PrayerHeaderDelegate] must reserve.
  ///
  /// Computed from the theme's own label metrics rather than measured, because the
  /// delegate has to state its extent before it lays out and the number of label
  /// strips depends on the resolved [PrayerGrid]. The height of the line itself is
  /// measured — see [AppTextTheme.lineHeight] for why `fontSize * height` is not
  /// close enough at 200% text.
  static double heightFor(
    PrayerGrid grid,
    TextTheme textTheme,
    TextScaler scaler,
  ) {
    final label =
        textTheme.labelSmall ?? const TextStyle(fontSize: AppFontSize.xs);
    final line = AppTextTheme.lineHeight(label, scaler);
    // One label line plus the strip gap, per strip, plus the delegate's own
    // bottom padding.
    return grid.stripsFor(PrayerKind.five.length) * (line + AppSpacing.xs) +
        AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final labels = PrayerKind.five
        .map((kind) => kind.localized(l10n))
        .toList(growable: false);

    return Padding(
      // [DayRow] insets its own content by this much inside the screen gutter, and
      // the strips are what these labels name — so the labels have to be inset by
      // the same amount or every column sits a half-word to the right of its
      // heading. The delegate only supplies the outer gutter.
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < labels.length; start += grid.columns)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  for (var i = 0; i < grid.columns; i++) ...[
                    if (i > 0) const SizedBox(width: PrayerGrid.columnGap),
                    Expanded(
                      child: i < labels.length
                          ? UiText(
                              labels[i],
                              type: UiTextType.labelSmall,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                              // No `labelSmall`'s wide tracking here: at
                              // `grid.columns` == 5 in English the labels are about
                              // 87dp each and tracking costs 4% of that. And unlike
                              // the old table this never has to abbreviate — the
                              // columns are now sized to the label.
                              letterSpacing: 0.2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps [PrayerLabelsHeader] on screen while the month scrolls under it.
///
/// Opaque rather than translucent, because a pinned header with any transparency
/// shows the times sliding through the prayer names, which defeats the reason for
/// pinning it. The hairline below it fades in only once the header has actually
/// been lifted, so the month does not open with a rule across it.
///
/// [height] is passed in rather than derived inside because a
/// `SliverPersistentHeader` has to state its extent before it lays out, and the
/// number of label strips depends on the resolved [PrayerGrid]. A fixed extent
/// would have been correct for five columns and wrong for the two-column layout a
/// 12-hour clock at 200% text resolves to.
class PrayerHeaderDelegate extends SliverPersistentHeaderDelegate {
  const PrayerHeaderDelegate({
    required this.child,
    required this.background,
    required this.hairline,
    required this.height,
  });

  final Widget child;
  final Color background;
  final Color hairline;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: background,
    child: Stack(
      fit: StackFit.expand,
      children: [
        // Padding rather than a centred child: the header's rows are
        // `crossAxisAlignment.stretch`, so they need the full width to line up
        // with the rows below.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.huge,
            0,
            AppSpacing.huge,
            AppSpacing.xs,
          ),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedOpacity(
            // 2dp of travel, then fully drawn: the rule should be there by the
            // time the header has visibly detached, not before.
            opacity: (shrinkOffset / 2).clamp(0.0, 1.0),
            duration: const Duration(milliseconds: 120),
            child: Container(height: 1, color: hairline),
          ),
        ),
      ],
    ),
  );

  @override
  bool shouldRebuild(PrayerHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.background != background ||
      oldDelegate.hairline != hairline ||
      // The extent is what sizes the sliver, so a delegate that kept the old
      // height would pin the labels inside a header laid out for another one.
      oldDelegate.height != height;
}
