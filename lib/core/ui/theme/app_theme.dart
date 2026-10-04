import 'package:flutter/material.dart';

import 'package:mawaqit/core/const/app_constants.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/ui/theme/text_theme.dart';

/// Material 3 theme assembly.
///
/// Built from a [ColorScheme.fromSeed] and then **overridden** at the roles that
/// carry meaning (feat.md §6): the hand-tuned emerald/gold pair below is the
/// brand, and the generated tonal palette only fills the long tail of container
/// roles. Dynamic colour is deliberately not used — a wallpaper-derived scheme
/// is unpredictable against a deep green brand and cannot guarantee the
/// adhan overlay's contrast.
///
/// One [AppTheme] instance is cached per (palette × brightness × language) so
/// switching tabs does not rebuild a 100-key map on every frame.
abstract final class AppTheme {
  const AppTheme._();

  static final Map<String, ThemeData> _cache = {};

  static ThemeData light({
    AppPalette palette = AppPalette.emerald,
    bool arabic = false,
  }) => _build(palette, Brightness.light, arabic: arabic);

  static ThemeData dark({
    AppPalette palette = AppPalette.emerald,
    bool arabic = false,
  }) => _build(palette, Brightness.dark, arabic: arabic);

  /// Drops every cached theme.
  ///
  /// Called when the persisted palette changes: without this a running app that
  /// toggles palettes in Settings would keep rendering the old one until the
  /// next cold start, because [MaterialApp] caches nothing but we do.
  static void invalidateCache() => _cache.clear();

  /// Tabular figures for countdowns and prayer times. See
  /// [AppTextTheme.tabular]; kept as a static here because that is where the
  /// existing hero already looks.
  static TextStyle numerals(TextStyle style) => AppTextTheme.tabular(style);

  static ThemeData _build(
    AppPalette palette,
    Brightness brightness, {
    required bool arabic,
  }) {
    final key = '${palette.name}-${brightness.name}-$arabic';
    return _cache.putIfAbsent(key, () {
      final scheme = _scheme(palette, brightness);
      final textTheme = AppTextTheme.build(
        scheme: scheme,
        brightness: brightness,
        arabic: arabic,
      );
      return _compose(scheme, textTheme, brightness);
    });
  }

  /// The seed supplies tonal harmony; the overrides supply the brand.
  static ColorScheme _scheme(AppPalette palette, Brightness brightness) {
    final seed = brightness == Brightness.light
        ? palette.lightSeed
        : palette.darkSeed;
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return generated.copyWith(
        primary: switch (palette) {
          AppPalette.emerald => AppColors.primaryEmerald,
          AppPalette.sage => AppColors.primarySage,
          AppPalette.midnight => AppColors.primaryMidnight,
        },
        onPrimary: AppColors.white,
        tertiary: switch (palette) {
          AppPalette.emerald => AppColors.goldLight,
          AppPalette.sage => AppColors.secondary,
          AppPalette.midnight => AppColors.amberLight,
        },
        onTertiary: AppColors.white,
        surface: AppColors.canvasLight,
        onSurface: AppColors.onSurfaceLight,
        surfaceContainerLowest: AppColors.cardLight,
        surfaceContainerLow: AppColors.containerLight,
        surfaceContainer: AppColors.surfaceContainerLight,
        surfaceContainerHigh: AppColors.surfaceContainerHighLight,
        surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
        // Wired explicitly rather than left to the ColorScheme defaults.
        // `flutter build` seeds `primaryContainer` from Material's baseline
        // purple, so omitting it leaves the selected nav pill on a lilac fill
        // against an emerald brand — visibly off-theme.
        //
        // Switched on the palette too, not just generated: `fromSeed` puts
        // emerald and sage within a hair of one another (`0xFFA3F2D8` vs
        // `0xFFAAF2CB`), which would leave the pill looking unchanged after the
        // user picked a different palette.
        primaryContainer: switch (palette) {
          AppPalette.emerald => AppColors.emeraldContainerLight,
          AppPalette.sage => AppColors.sageContainerLight,
          AppPalette.midnight => AppColors.midnightContainerLight,
        },
        onPrimaryContainer: switch (palette) {
          AppPalette.emerald => AppColors.onEmeraldContainerLight,
          AppPalette.sage => AppColors.onSageContainerLight,
          AppPalette.midnight => AppColors.onMidnightContainerLight,
        },
        secondaryContainer: AppColors.secondaryContainerLight,
        onSecondaryContainer: AppColors.onSecondaryContainerLight,
        onSurfaceVariant: AppColors.onSurfaceMutedLight,
        outline: AppColors.onSurfaceMutedLight,
        outlineVariant: AppColors.hairlineLight,
        error: AppColors.error,
      );
    }

    return generated.copyWith(
      primary: switch (palette) {
        AppPalette.emerald => AppColors.primaryEmeraldDark,
        AppPalette.sage => AppColors.primarySageDark,
        AppPalette.midnight => AppColors.primaryMidnightDark,
      },
      onPrimary: palette == AppPalette.sage
          ? AppColors.white
          : AppColors.deepInk,
      tertiary: switch (palette) {
        AppPalette.emerald => AppColors.goldDark,
        AppPalette.sage => AppColors.radiantSage,
        AppPalette.midnight => AppColors.amberDark,
      },
      onTertiary: AppColors.white,
      surface: AppColors.canvasDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerLowest: AppColors.sunkenDark,
      surfaceContainerLow: AppColors.cardDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      onSecondary: AppColors.onSecondaryDark,
      // Per-palette for the same reason as the light branch: this is the
      // selected nav pill's fill, so it has to follow the palette the user
      // picked in Settings → Appearance.
      primaryContainer: switch (palette) {
        AppPalette.emerald => AppColors.emeraldContainerDark,
        AppPalette.sage => AppColors.sageContainerDark,
        AppPalette.midnight => AppColors.midnightContainerDark,
      },
      onPrimaryContainer: switch (palette) {
        AppPalette.emerald => AppColors.onEmeraldContainerDark,
        AppPalette.sage => AppColors.onSageContainerDark,
        AppPalette.midnight => AppColors.onMidnightContainerDark,
      },
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
      onSurfaceVariant: AppColors.onSurfaceMutedDark,
      outline: AppColors.onSurfaceMutedDark,
      outlineVariant: AppColors.hairlineDark,
      error: AppColors.errorDark,
    );
  }

  static ThemeData _compose(
    ColorScheme scheme,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;
    final cardColor = isLight ? AppColors.cardLight : AppColors.cardDark;
    final primary = scheme.primary;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
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
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? cardColor
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary
                : scheme.onSurfaceVariant,
          ),
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
          color: isLight ? AppColors.white : AppColors.onSurfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
