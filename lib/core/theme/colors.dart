import 'package:flutter/material.dart';

/// Sage Emerald — calm, non-symbolic green for the Mawaqit prayer app.
///
/// Single source of truth for every colour in the project: light/dark surfaces,
/// the Material 3 ColorScheme inputs used by [`AppTheme`] and the ARGB ints
/// consumed by the Android Home Widget. Widget code should never spell a hex
/// literal directly — always reach for a token here.
abstract final class AppColors {
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
  static const Color canvasDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF181918);
  static const Color sunkenDark = Color(0xFF141414);
  static const Color hairlineDark = Color(0xFF252725);
  static const Color onSurfaceDark = Color(0xFFEDEDEA);
  static const Color onSurfaceMutedDark = Color(0xFF8A918C);

  // ─────────────────────────── Brand accents ────────────────────────────
  static const Color primaryLight = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF3E9B76);
  static const Color secondary = Color(0xFF4A7C63); // dusty eucalyptus
  static const Color tertiary = Color(0xFF8FA998); // silver sage

  static const Color radiantSage = Color(0xFFA4F3CA);
  static const Color deepInk = Color(0xFF002113);

  /// Brand green at 20% alpha — soft chips and widget glows.
  static const Color primaryTint = Color(0x332E7D5B);

  /// Dark forest green — the adhan overlay's deep gradient anchor.
  static const Color darkForest = Color(0xFF0A3524);

  /// Subtle hairline overlays for cards & rows (near-transparent black / white)
  /// that read on any tonal fill.
  static const Color hairlineOverlayLight = Color(0x0A000000);
  static const Color hairlineOverlayDark = Color(0x0FFFFFFF);

  /// Generic soft drop shadow (10% black) for floating hunks like the
  /// segmented control's highlight pill.
  static const Color shadowSoft = Color(0x1A000000);

  /// Pure white on-brand highlights (text on sage, chips).
  static const Color white = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFBA1A1A);

  // ───────────────────── Light ColorScheme containers ───────────────────
  static const Color surfaceContainerLight = Color(0xFFEEEEEB);
  static const Color surfaceContainerHighLight = Color(0xFFE8E8E5);
  static const Color surfaceContainerHighestLight = Color(0xFFE2E3E0);
  static const Color secondaryContainerLight = Color(0xFFD6E5DB);
  static const Color onSecondaryContainerLight = Color(0xFF1D5039);

  // ────────────────────── Dark ColorScheme containers ───────────────────
  static const Color primaryContainerDark = Color(0xFF1E4A38);
  static const Color onPrimaryContainerDark = Color(0xFFC9F5DD);
  static const Color onSecondaryDark = Color(0xFF22302A);
  static const Color secondaryContainerDark = Color(0xFF38503F);
  static const Color onSecondaryContainerDark = Color(0xFFC9E2CF);
  static const Color tertiaryDark = Color(0xFFA9BFB0);
  static const Color onTertiaryDark = Color(0xFF213027);
  static const Color surfaceContainerDark = Color(0xFF1B1C1B);
  static const Color surfaceContainerHighDark = Color(0xFF1F211F);
  static const Color surfaceContainerHighestDark = Color(0xFF232524);
  static const Color errorDark = Color(0xFFFFB4AB);

  // ─────────────────────── Home Widget surfaces ─────────────────────────
  /// The Android home-screen card's own palette (Glance surface), kept here so
  /// it stays versioned with the app theme.
  static const Color widgetCanvasLight = Color(0xFFF7F8F5);
  static const Color widgetCanvasDark = Color(0xFF131A16);
  static const Color widgetHairlineLight = Color(0xFFE2E6E1);
  static const Color widgetHairlineDark = Color(0xFF1E2A23);

  /// Brighter sage used for dark-mode progress/accents on the widget.
  static const Color widgetAccentDark = Color(0xFF4ADE80);
  static const Color widgetAccentDarkTint = Color(0x334ADE80);

  static const Color widgetMutedLight = Color(0x666F7A72);
  static const Color widgetMutedDark = Color(0x668A918C);
  static const Color widgetMutedTintLight = Color(0x336F7A72);
  static const Color widgetMutedTintDark = Color(0x338A918C);

  /// Raw ARGB ints for non-[Color] consumers (Home Widget annotations, native
  /// surfaces) that must stay in sync with the palettes above.
  static const int primaryLightArgb = 0xFF2E7D5B;
  static const int primaryDarkArgb = 0xFF3E9B76;
  static const int radiantSageArgb = 0xFFA4F3CA;
  static const int primaryTintArgb = 0x332E7D5B;
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