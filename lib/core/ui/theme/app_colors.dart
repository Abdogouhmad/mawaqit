/// Every colour in the project, as raw literals. Widget code must never spell a
/// hex value — it reaches a token here or a [ColorScheme] role instead.
///
/// The app ships **no dynamic colour** (feat.md §6): the wallpaper-derived
/// scheme is unpredictable against a deep green/gold brand, and it would break
/// the adhan overlay's contrast guarantees. What it ships instead is a small set
/// of hand-tuned [AppPalette]s the user can choose in Settings → Appearance.
library;

import 'package:flutter/material.dart';

/// One complete, hand-checked colour scheme pair.
///
/// Held as an enum rather than a `ColorScheme` pair so the palette is *data*:
/// it can be persisted by name, listed in Settings, and unit-tested for contrast
/// without a `BuildContext`.
enum AppPalette {
  /// Deep emerald + sand gold. The brand default (feat.md §6).
  emerald,

  /// The pre-1.0 sage palette, kept so existing installs keep the app they know.
  sage,

  /// Midnight indigo + warm amber. High-contrast dark alternative.
  midnight;

  String get storageKey => name;

  static AppPalette fromStorageKey(String? key) => AppPalette.values.firstWhere(
    (p) => p.name == key,
    orElse: () => AppPalette.emerald,
  );

  /// Light-mode seed. The schemes are hand-authored rather than generated from
  /// this, but the seed is what `ColorScheme.fromSeed` would key off, and it is
  /// the value used for the Material You–style tonal accents.
  Color get lightSeed => switch (this) {
    AppPalette.emerald => AppColors.emeraldSeed,
    AppPalette.sage => AppColors.sageSeed,
    AppPalette.midnight => AppColors.midnightSeed,
  };

  Color get darkSeed => switch (this) {
    AppPalette.emerald => AppColors.emeraldSeedDark,
    AppPalette.sage => AppColors.sageSeedDark,
    AppPalette.midnight => AppColors.midnightSeedDark,
  };
}

/// Raw colour literals — the single source of truth behind [AppPalette].
abstract final class AppColors {
  const AppColors._();

  // ───────────────────────────── Palette seeds ───────────────────────────
  static const Color emeraldSeed = Color(0xFF0F5C4A);
  static const Color emeraldSeedDark = Color(0xFF3FA184);
  static const Color sageSeed = Color(0xFF2E7D5B);
  static const Color sageSeedDark = Color(0xFF3E9B76);
  static const Color midnightSeed = Color(0xFF2E3A7A);
  static const Color midnightSeedDark = Color(0xFF9BA6F0);

  // ─────────────────────── Emerald (brand default) ───────────────────────
  /// Deep emerald primary — the brand's core colour.
  static const Color primaryEmerald = Color(0xFF0F5C4A);

  /// Legible emerald for dark surfaces; the light primary fails contrast on
  /// near-black, so dark mode gets its own lighter step rather than reusing it.
  static const Color primaryEmeraldDark = Color(0xFF3FA184);

  /// Sand gold tertiary, used for sunrise/sunset accents and the times calendar.
  static const Color goldLight = Color(0xFFC9A24B);
  static const Color goldDark = Color(0xFFE0BC6C);

  /// The app's dark canvas (feat.md §6).
  static const Color canvasDark = Color(0xFF0B1512);

  /// Deep forest anchor for the adhan overlay's gradient.
  static const Color darkForest = Color(0xFF0A3524);

  // ─────────────────────── Sage (legacy palette) ─────────────────────────
  static const Color primarySage = Color(0xFF2E7D5B);
  static const Color primarySageDark = Color(0xFF3E9B76);

  /// Dusty eucalyptus — the sage palette's secondary accent.
  static const Color secondary = Color(0xFF4A7C63);
  static const Color tertiary = Color(0xFF8FA998);

  static const Color radiantSage = Color(0xFFA4F3CA);
  static const Color deepInk = Color(0xFF002113);

  // ────────────────────── Midnight (dark palette) ────────────────────────
  static const Color primaryMidnight = Color(0xFF2E3A7A);
  static const Color primaryMidnightDark = Color(0xFF9BA6F0);
  static const Color amberLight = Color(0xFFC98A2B);
  static const Color amberDark = Color(0xFFE8B768);

  // ─────────────────────────── Light surfaces ───────────────────────────
  static const Color canvasLight = Color(0xFFFAFAF7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color containerLight = Color(0xFFF2F2ED);
  static const Color hairlineLight = Color(0xFFE7E7E0);
  static const Color onSurfaceLight = Color(0xFF191C1A);
  static const Color onSurfaceMutedLight = Color(0xFF6D736F);

  /// Neutral tile tint for "passed" prayer rows in light mode.
  static const Color tileInactiveLight = Color(0xFFF4F4F1);

  // ─────────────────────────── Dark surfaces ────────────────────────────
  static const Color cardDark = Color(0xFF121815);
  static const Color sunkenDark = Color(0xFF0E1412);
  static const Color hairlineDark = Color(0xFF252B28);
  static const Color onSurfaceDark = Color(0xFFEDEDEA);
  static const Color onSurfaceMutedDark = Color(0xFF8A918C);

  // ───────────────────────── Shared brand extras ─────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  /// Brand tint used for soft chips, glows and the home widget's progress track.
  static const Color primaryTint = Color(0x330F5C4A);

  /// Hairline overlays that read on any tonal fill.
  static const Color hairlineOverlayLight = Color(0x0A000000);
  static const Color hairlineOverlayDark = Color(0x0FFFFFFF);

  /// Soft drop shadow for floating hunks such as the nav bar.
  static const Color shadowSoft = Color(0x1A000000);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);

  // ───────────────────── Light ColorScheme containers ───────────────────
  static const Color surfaceContainerLight = Color(0xFFEEEEEB);
  static const Color surfaceContainerHighLight = Color(0xFFE8E8E5);
  static const Color surfaceContainerHighestLight = Color(0xFFE2E3E0);
  static const Color secondaryContainerLight = Color(0xFFD6E5DB);
  static const Color onSecondaryContainerLight = Color(0xFF1D5039);

  // ───────────────── Dark primary containers, per palette ───────────────
  // `primaryContainer` is the fill behind the selected nav pill and behind the
  // tinted fills on the home, times and update screens. It is the one
  // container role that has to carry the palette: hardcoding it to emerald left
  // the nav bar on green after the user picked sage or midnight. Each palette
  // therefore owns a pair, kept in the same tonal register as its `primary` —
  // a pale tint of the brand hue with near-black content in light mode, a deep
  // tint with a pale content colour in dark mode.
  static const Color emeraldContainerLight = Color(0xFFBFE4D6);
  static const Color onEmeraldContainerLight = Color(0xFF00291E);

  /// Dustier and yellower than the emerald pair, tracking `primarySage`.
  static const Color sageContainerLight = Color(0xFFC4E4CC);
  static const Color onSageContainerLight = Color(0xFF10301C);

  /// Periwinkle, tracking `primaryMidnight` — the only palette whose container
  /// is not a green, so the pill reads as unmistakably indigo.
  static const Color midnightContainerLight = Color(0xFFDEE0FF);
  static const Color onMidnightContainerLight = Color(0xFF141A5E);

  // ────────────────────── Dark ColorScheme containers ────────────────────
  static const Color onSecondaryDark = Color(0xFF22302A);
  static const Color secondaryContainerDark = Color(0xFF38503F);
  static const Color onSecondaryContainerDark = Color(0xFFC9E2CF);
  static const Color surfaceContainerDark = Color(0xFF151B18);
  static const Color surfaceContainerHighDark = Color(0xFF19201D);
  static const Color surfaceContainerHighestDark = Color(0xFF1D2521);

  static const Color emeraldContainerDark = Color(0xFF1E4A38);
  static const Color onEmeraldContainerDark = Color(0xFFC9F5DD);

  /// Warmer and a step lighter than the emerald pair, tracking `primarySageDark`.
  static const Color sageContainerDark = Color(0xFF2A523A);
  static const Color onSageContainerDark = Color(0xFFD4F2E0);

  /// Indigo deep enough to sit under the dark canvas without glowing.
  static const Color midnightContainerDark = Color(0xFF333C72);
  static const Color onMidnightContainerDark = Color(0xFFDEE0FF);

  // ─────────────────────── Home Widget surfaces ─────────────────────────
  static const Color widgetCanvasLight = Color(0xFFF7F8F5);
  static const Color widgetCanvasDark = Color(0xFF131A16);
  static const Color widgetHairlineLight = Color(0xFFE2E6E1);
  static const Color widgetHairlineDark = Color(0xFF1E2A23);
  static const Color widgetAccentDark = Color(0xFF4ADE80);
  static const Color widgetAccentDarkTint = Color(0x334ADE80);
  static const Color widgetMutedLight = Color(0x666F7A72);
  static const Color widgetMutedDark = Color(0x668A918C);
  static const Color widgetMutedTintLight = Color(0x336F7A72);
  static const Color widgetMutedTintDark = Color(0x338A918C);

  // ──────────────────────── Raw ARGB for native ─────────────────────────
  // The Android home-screen card (Glance) annotates ints, not Colors; these
  // mirror the values above so the widget can never drift from the app theme.
  static const int emeraldPrimaryArgb = 0xFF0F5C4A;
  static const int emeraldPrimaryDarkArgb = 0xFF3FA184;
  static const int goldArgb = 0xFFC9A24B;
  static const int radiantSageArgb = 0xFFA4F3CA;
  static const int whiteArgb = 0xFFFFFFFF;
  static const int widgetCanvasLightArgb = 0xFFF7F8F5;
  static const int widgetCanvasDarkArgb = 0xFF131A16;
  static const int widgetHairlineLightArgb = 0xFFE2E6E1;
  static const int widgetHairlineDarkArgb = 0xFF1E2A23;
  static const int widgetAccentDarkArgb = 0xFF4ADE80;
  static const int widgetAccentDarkTintArgb = 0x334ADE80;
  static const int widgetMutedLightArgb = 0x666F7A72;
  static const int widgetMutedDarkArgb = 0x668A918C;
  static const int widgetMutedTintLightArgb = 0x336F7A72;
  static const int widgetMutedTintDarkArgb = 0x338A918C;
}
