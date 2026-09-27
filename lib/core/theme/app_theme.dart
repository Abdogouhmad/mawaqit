import 'package:flutter/material.dart';

import 'package:mawaqit/core/constants.dart';
import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';

/// Material 3 "Sage Emerald" theme — warmed neutral canvas, muted gemstone
/// green accent, Manrope type, soft rounded surfaces. Expressive but calm.
abstract final class AppTheme {
  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.primaryLight,
    onPrimary: Colors.white,
    primaryContainer: AppColors.radiantSage,
    onPrimaryContainer: AppColors.deepInk,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainerLight,
    onSecondaryContainer: AppColors.onSecondaryContainerLight,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    surface: AppColors.canvasLight,
    onSurface: AppColors.onSurfaceLight,
    surfaceContainerLowest: AppColors.cardLight,
    surfaceContainerLow: AppColors.containerLight,
    surfaceContainer: AppColors.surfaceContainerLight,
    surfaceContainerHigh: AppColors.surfaceContainerHighLight,
    surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
    onSurfaceVariant: AppColors.onSurfaceMutedLight,
    outline: AppColors.onSurfaceMutedLight,
    outlineVariant: AppColors.hairlineLight,
    error: AppColors.error,
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppColors.primaryDark,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.tertiaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    surface: AppColors.canvasDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLowest: AppColors.cardDark,
    surfaceContainerLow: AppColors.sunkenDark,
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    onSurfaceVariant: AppColors.onSurfaceMutedDark,
    outline: AppColors.onSurfaceMutedDark,
    outlineVariant: AppColors.hairlineDark,
    error: AppColors.errorDark,
  );

  static ThemeData light({bool arabic = false}) =>
      _build(_lightScheme, Brightness.light, arabic: arabic);

  static ThemeData dark({bool arabic = false}) =>
      _build(_darkScheme, Brightness.dark, arabic: arabic);

  static ThemeData _build(
    ColorScheme scheme,
    Brightness brightness, {
    bool arabic = false,
  }) {
    final isLight = brightness == Brightness.light;
    final cardColor = isLight ? AppColors.cardLight : AppColors.cardDark;
    final primary = scheme.primary;

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: AppConstants.fontFamily,
      fontFamilyFallback: AppConstants.fontFamilyFallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontSize: AppFontSize.displayLg,
        height: 1.1,
        fontWeight: FontWeight.w200,
        letterSpacing: -1.5,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontSize: AppFontSize.displayMd,
        height: 1.15,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.2,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontSize: AppFontSize.displaySm,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: AppFontSize.headline,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: AppFontSize.xxl,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: AppFontSize.xl,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: AppFontSize.lg,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: AppFontSize.md,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: AppFontSize.md,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: AppFontSize.sm,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: AppFontSize.xs,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: arabic ? _untacked(textTheme) : textTheme,
      // Both, not just the text theme: widgets that build their own TextStyle
      // from the ThemeData (and the default Material styles) still need the
      // Arabic fallback, otherwise a stray `Text` renders Arabic in the system
      // font while the rest of the screen is in Cairo.
      fontFamily: AppConstants.fontFamily,
      fontFamilyFallback: AppConstants.fontFamilyFallback,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: const CircleBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.jumbo,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedColor: primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.mini),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.hairlineLight : AppColors.hairlineDark,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(AppSpacing.touch, AppSpacing.touch),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.giga,
            vertical: AppSpacing.xxl,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(AppSpacing.touch, AppSpacing.touch),
          side: BorderSide(color: primary.withValues(alpha: 0.4)),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cardColor;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return scheme.onSurfaceVariant;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.zero)),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.onSurfaceLight
            : AppColors.cardDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : AppColors.onSurfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  /// Tabular figures for countdowns and prayer times to prevent jitter.
  static TextStyle numerals(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    fontVariations: const [FontVariation('wght', 300)],
  );

  /// Strips every `letterSpacing` from [theme].
  ///
  /// The tracking in this file is dialled in for Latin: negative on the large
  /// display sizes, positive on the small uppercase-ish labels. None of it
  /// transfers to Arabic. Arabic script joins its letters through contextual
  /// forms, so inserting space between glyphs breaks the word into a row of
  /// disconnected letters — it reads as broken rather than as "spaced out", which
  /// is why Arabic typesetting guidance is to leave tracking at zero.
  ///
  /// Done as a post-pass over the finished theme rather than by branching at
  /// each of the ten `letterSpacing` sites, so a new style cannot forget the
  /// Arabic case.
  static TextTheme _untacked(TextTheme theme) => theme.copyWith(
    displayLarge: theme.displayLarge?.copyWith(letterSpacing: 0),
    displayMedium: theme.displayMedium?.copyWith(letterSpacing: 0),
    displaySmall: theme.displaySmall?.copyWith(letterSpacing: 0),
    headlineLarge: theme.headlineLarge?.copyWith(letterSpacing: 0),
    headlineMedium: theme.headlineMedium?.copyWith(letterSpacing: 0),
    headlineSmall: theme.headlineSmall?.copyWith(letterSpacing: 0),
    titleLarge: theme.titleLarge?.copyWith(letterSpacing: 0),
    titleMedium: theme.titleMedium?.copyWith(letterSpacing: 0),
    titleSmall: theme.titleSmall?.copyWith(letterSpacing: 0),
    bodyLarge: theme.bodyLarge?.copyWith(letterSpacing: 0),
    bodyMedium: theme.bodyMedium?.copyWith(letterSpacing: 0),
    bodySmall: theme.bodySmall?.copyWith(letterSpacing: 0),
    labelLarge: theme.labelLarge?.copyWith(letterSpacing: 0),
    labelMedium: theme.labelMedium?.copyWith(letterSpacing: 0),
    labelSmall: theme.labelSmall?.copyWith(letterSpacing: 0),
  );
}
