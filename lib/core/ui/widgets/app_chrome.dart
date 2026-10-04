import 'package:flutter/material.dart';

/// Layout metrics for the app's floating chrome — the detached pill navigation
/// bar.
///
/// The bar is **not** a `bottomNavigationBar`, so Flutter reserves no space for
/// it. Two consequences the rest of the app depends on:
///
///  * every scrollable must end with [scrollBottomPadding] so its last item is
///    never hidden behind the pill;
///  * the shell uses `extendBody: true` and positions the bar with
///    [navBottomOffset].
///
/// Renaming any value here is a layout change in every screen, which is why they
/// live in one file rather than as literals at the call sites.
abstract final class AppChrome {
  const AppChrome._();

  /// Horizontal margin between the pill and the screen edge.
  ///
  /// Wide enough that the pill reads as detached from the screen rather than as
  /// a full-width bar with rounded ends. Too wide and it stops spanning enough
  /// for the selected label to open up inside it.
  static const double horizontalMargin = 22;

  /// Height of the pill itself.
  static const double navHeight = 68;

  /// Gap between the pill and the bottom system inset.
  static const double navBottomMargin = 16;

  /// Vertical extent the chrome occupies, ignoring system insets.
  static const double navExtent = navHeight + navBottomMargin;

  /// Max content width before the layout starts constraining and centring, so
  /// phone-first screens do not stretch across a tablet or unfolded foldable.
  static const double maxContentWidth = 600;

  /// Bottom system inset (gesture bar / navigation buttons).
  static double systemBottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  /// Distance from the screen's bottom edge to the pill's bottom edge.
  static double navBottomOffset(BuildContext context) =>
      navBottomMargin + systemBottom(context);

  /// Bottom padding a scrollable must add to clear the floating chrome.
  static double scrollBottomPadding(
    BuildContext context, {
    double extra = 24,
  }) => navExtent + systemBottom(context) + extra;

  /// Padding for a screen's scrollable body: symmetric sides, chrome clearance
  /// at the bottom.
  static EdgeInsets screenPadding(
    BuildContext context, {
    double horizontal = 20,
    double top = 0,
    double extraBottom = 0,
  }) => EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    scrollBottomPadding(context, extra: extraBottom),
  );

  /// Centres and width-caps [child] on large screens.
  static Widget constrain(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );
}
