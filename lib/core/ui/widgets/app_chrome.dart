import 'package:flutter/material.dart';

/// Layout metrics shared by the app's screens.
///
/// The bottom navigation is a standard Material `NavigationBar` in the
/// `Scaffold.bottomNavigationBar` slot, so Flutter reserves its height: screens
/// no longer have to clear a detached floating bar. [scrollBottomPadding] is
/// therefore just a little breathing room under the last list item, and
/// [constrain] keeps phone-first layouts centred on tablets and foldables.
abstract final class AppChrome {
  const AppChrome._();

  /// Max content width before the layout starts constraining and centring, so
  /// phone-first screens do not stretch across a tablet or unfolded foldable.
  static const double maxContentWidth = 600;

  /// Bottom inset a scrollable adds so its last item is not flush against the
  /// navigation bar. The bar's own height is reserved by the `Scaffold`.
  static double scrollBottomPadding(
    BuildContext context, {
    double extra = 16,
  }) => extra;

  /// Padding for a screen's scrollable body: symmetric sides, a little bottom
  /// breathing room above the navigation bar.
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
