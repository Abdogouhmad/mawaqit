import 'package:flutter/material.dart';

/// Sage Emerald — calm, non-symbolic green for the Waqt prayer app.
abstract final class AppColors {
  // Light mode
  static const Color canvasLight = Color(0xFFFAFAF7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color containerLight = Color(0xFFF2F2ED);
  static const Color hairlineLight = Color(0xFFE7E7E0);
  static const Color onSurfaceLight = Color(0xFF191C1A);
  static const Color onSurfaceMutedLight = Color(0xFF6D736F);

  // Dark mode
  static const Color canvasDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF181918);
  static const Color sunkenDark = Color(0xFF141414);
  static const Color hairlineDark = Color(0xFF252725);
  static const Color onSurfaceDark = Color(0xFFEDEDEA);
  static const Color onSurfaceMutedDark = Color(0xFF8A918C);

  // Brand accents
  static const Color primaryLight = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF3E9B76);
  static const Color secondary = Color(0xFF4A7C63); // dusty eucalyptus
  static const Color tertiary = Color(0xFF8FA998); // silver sage

  static const Color radiantSage = Color(0xFFA4F3CA);
  static const Color deepInk = Color(0xFF002113);

  static const Color error = Color(0xFFBA1A1A);
}