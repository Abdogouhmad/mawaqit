// ignore_for_file: depend_on_referenced_packages
import 'package:mawaqit/core/ui/theme/app_colors.dart';

/// Native mirror of the app's design tokens.
///
/// Glance annotations take plain dp `double`s and ARGB `int`s, so the widget
/// DSL cannot import `AppSpacing`/`AppRadius` directly. Keeping the *named*
/// values here means a widget change is still a token change, not a magic
/// number, and every value is tied back to its Flutter counterpart.
abstract final class WidgetTokens {
  /// The one root tap target the generated Glance widget can emit. Kept here so
  /// the routing test can assert the parser accepts exactly what the DSL sends.
  static const String launchUrl = 'mawaqit:///times';

  // AppSpacing.xl / md / sm / xs / xxs.
  static const double spaceXl = 12;
  static const double spaceMd = 8;
  static const double spaceSm = 6;
  static const double spaceXs = 4;
  static const double spaceXxs = 2;

  // AppRadius.md / lg.
  static const double radiusMd = 14;
  static const double radiusLg = 24;

  // AppStroke.hairline / focus.
  static const double strokeHairline = 1;
  static const double strokeFocus = 2;

  // AppIconSize.sm / xl.
  static const double iconSm = 16;
  static const double iconLg = 20;

  // Prayer-sequence dots: active / past / upcoming.
  static const double dotActive = 9;
  static const double dotIdle = 6;

  /// True black surface used only when AMOLED is on in dark mode.
  static const int canvasAmoledArgb = AppColors.amoledSurfaceArgb;

  /// Muted dot tints on true black: slightly brighter than dark-theme values so
  /// the five-dot row keeps the same contrast ratio as the dark palette.
  static const int mutedAmoledArgb = AppColors.widgetMutedAmoledArgb;
  static const int mutedTintAmoledArgb = AppColors.widgetMutedTintAmoledArgb;
}
