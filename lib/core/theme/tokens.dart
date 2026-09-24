/// Central design tokens — the single source of truth for spacing, radius,
/// type scale and icon sizes, so the UI stays consistent and themeable.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 14;
  static const double xxxl = 16;
  static const double jumbo = 18;
  static const double huge = 20;
  static const double mega = 22;
  static const double giga = 24;
  static const double tera = 28;
  static const double block = 30;
  static const double blockLg = 26;
  static const double emphasis = 34;
  static const double pageBottom = 40;
  static const double control = 40;
  static const double touch = 48;
  static const double progress = 320;
  static const double offsetLg = 80;
  static const double offsetXl = 160;
}

/// Corner radii. `pill` is an intentionally large value used for capsule
/// shapes that should stay fully rounded regardless of their size.
abstract final class AppRadius {
  static const double mini = 9;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double sheet = 28;
  static const double chip = 7;
  static const double pill = 999;
}

abstract final class AppFontSize {
  static const double xs = 11;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double headline = 24;
  static const double displaySm = 32;
  static const double displayMd = 44;
  static const double displayLg = 56;
}

abstract final class AppIconSize {
  static const double xs = 13;
  static const double sm = 14;
  static const double md = 17;
  static const double lg = 19;
  static const double xl = 20;
  static const double xxl = 21;
  static const double display = 56;
}
