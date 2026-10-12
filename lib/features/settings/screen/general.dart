import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/core/ui/theme/motion.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Settings → General.
///
/// Language and appearance, pulled off the main settings list into one screen.
/// Three decisions, in the order they are usually made: what the app speaks,
/// how bright it is, what colour it takes — then the fine print that trades
/// polish for quiet.
///
/// A pushed route rather than a tab, so it renders its own [Scaffold] and
/// [AppBar] with a back button — the same shape as `OtaUpdateScreen`.
class GeneralScreen extends ConsumerWidget {
  const GeneralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.settingsSectionGeneral,
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: asyncSettings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: UiText(error.toString(), textAlign: TextAlign.center),
          ),
          data: (settings) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.huge,
              AppSpacing.sm,
              AppSpacing.huge,
              AppSpacing.pageBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Language ──────────────────────────────────────────────
                SectionHeader(
                  label: l10n.settingsLanguage,
                  description: l10n.settingsGeneralLanguageDesc,
                  icon: Icons.language,
                ),
                SettingsGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: _LanguageSelector(
                        value: settings.language,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          controller.save(settings.copyWith(language: value));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.mega),

                // ── Theme ─────────────────────────────────────────────────
                SectionHeader(
                  label: l10n.settingsTheme,
                  description: l10n.settingsAppearanceDesc,
                  icon: Icons.palette_outlined,
                ),
                SettingsGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: _ThemeModeSelector(
                        value: settings.themeMode,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          controller.save(settings.copyWith(themeMode: value));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _ThemePreview(),
                const SizedBox(height: AppSpacing.xxl),
                _PaletteSettingRow(
                  value: settings.palette,
                  onChanged: (palette) {
                    HapticFeedback.selectionClick();
                    controller.save(settings.copyWith(palette: palette));
                  },
                ),
                const SizedBox(height: AppSpacing.mega),

                // ── Surfaces ──────────────────────────────────────────────
                SectionHeader(
                  label: l10n.settingsGeneralSurfaces,
                  description: l10n.settingsGeneralSurfacesDesc,
                  icon: Icons.auto_awesome_outlined,
                ),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.blur_off_outlined,
                      title: l10n.appearanceReduceTransparency,
                      subtitle: l10n.appearanceReduceTransparencyHint,
                      trailing: Switch(
                        value: settings.reduceTransparency,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          controller.save(
                            settings.copyWith(reduceTransparency: value),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.motion_photos_off_outlined,
                      title: l10n.appearanceMotion,
                      subtitle: l10n.appearanceMotionHint,
                      trailing: Switch(
                        value: settings.reduceMotion,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          controller.save(settings.copyWith(reduceMotion: value));
                        },
                      ),
                    ),
                    _AmoledRow(
                      value: settings.amoled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        controller.save(settings.copyWith(amoled: value));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// True-black switch.
///
/// Disabled — not hidden — while the app is in light mode, so the preference is
/// still visible and its remembered state can be changed. Its subtitle explains
/// why it cannot be toggled yet.
class _AmoledRow extends StatelessWidget {
  const _AmoledRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingsRow(
      icon: Icons.contrast_outlined,
      title: l10n.settingsAmoled,
      subtitle: isDark ? l10n.settingsAmoledHint : l10n.settingsAmoledDisabled,
      trailing: Switch(
        value: value,
        onChanged: isDark ? onChanged : null,
      ),
    );
  }
}

/// Light / Dark / System as three tappable tiles rather than a segmented bar.
///
/// A tile can carry an icon *and* a word without fighting for horizontal space,
/// and the selected one is filled with the palette's own tint, so the control
/// previews the choice as it makes it.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ChoiceTile(
              icon: Icons.brightness_auto_outlined,
              label: l10n.settingsThemeSystem,
              selected: value == AppThemeMode.system,
              onTap: () => onChanged(AppThemeMode.system),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ChoiceTile(
              icon: Icons.light_mode_outlined,
              label: l10n.settingsThemeLight,
              selected: value == AppThemeMode.light,
              onTap: () => onChanged(AppThemeMode.light),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ChoiceTile(
              icon: Icons.dark_mode_outlined,
              label: l10n.settingsThemeDark,
              selected: value == AppThemeMode.dark,
              onTap: () => onChanged(AppThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four languages as a 2×2 of tiles.
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(AppLanguage language, IconData icon) => _ChoiceTile(
      icon: icon,
      label: language.localized(l10n),
      selected: value == language,
      onTap: () => onChanged(language),
    );

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: tile(AppLanguage.system, Icons.settings_suggest_outlined),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: tile(AppLanguage.english, Icons.abc_rounded)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tile(AppLanguage.arabic, Icons.translate_rounded)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: tile(AppLanguage.french, Icons.language_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}

/// One selectable tile: icon over label, tinted and outlined when selected.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = selected ? scheme.primaryContainer : scheme.surfaceContainer;
    final content = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.jumbo,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: content, size: AppIconSize.xl),
              const SizedBox(height: AppSpacing.sm),
              UiText(
                label,
                type: UiTextType.labelMedium,
                color: content,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A miniature of the home screen's prayer card, rendered in the active theme.
///
/// Nine coloured discs say nothing about what a palette *does*; this answers the
/// question the user actually has — "what will my app look like?" — using only
/// `ColorScheme` roles, so it cannot drift from the real screens. It is a plain
/// [AppCard] on the live theme, so it follows a palette, mode and AMOLED the
/// instant they are tapped.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AppCard(
      color: scheme.primaryContainer,
      borderColor: Colors.transparent,
      ambient: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(
            l10n.homeNextPrayer,
            type: UiTextType.labelSmall,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: UiText(
                  l10n.prayerMaghrib,
                  type: UiTextType.headlineSmall,
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: UiText(
                  '18:42',
                  type: UiTextType.labelLarge,
                  color: scheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Palette picker.
///
/// A wrapping grid of two-tone discs rather than a single row of words: a
/// palette differs in *colour*, so the control shows the thing being chosen.
/// The discs flow to as many rows as the width allows, which is what keeps nine
/// palettes usable on a 320dp phone without a breakpoint. Names stay as the
/// semantic label so a screen reader announces what each disc is.
class _PaletteSettingRow extends StatelessWidget {
  const _PaletteSettingRow({required this.value, required this.onChanged});

  final AppPalette value;
  final ValueChanged<AppPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.palette_outlined),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      l10n.appearancePalette,
                      type: UiTextType.titleMedium,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    UiText(
                      value.localized(l10n),
                      type: UiTextType.labelMedium,
                      color: scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: [
              for (final palette in AppPalette.values)
                _PaletteSwatch(
                  scheme: AppTheme.schemeFor(palette, brightness),
                  selected: palette == value,
                  label: palette.localized(l10n),
                  onTap: () => onChanged(palette),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One selectable palette disc: the palette's own `primary` with a `tertiary`
/// half-disc peeking out of the bottom-right, and a check when selected.
///
/// The two-tone disc is what makes several solid circles tellable apart at a
/// glance; a single flat fill would leave Emerald and Sage nearly identical.
/// The disc is drawn from the palette's own [scheme], while the selection ring
/// uses the *app's* primary, so a selected disc reads as selected even in a
/// palette it is not itself.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.scheme,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final ColorScheme scheme;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  static const double _diameter = 46;
  static const double _accent = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ring = theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                width: _diameter,
                height: _diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  border: Border.all(
                    color: selected ? ring : theme.colorScheme.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: scheme.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: _accent,
                          height: _accent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      if (selected)
                        Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: scheme.onPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: _diameter + AppSpacing.giga,
                child: UiText(
                  label,
                  type: UiTextType.labelSmall,
                  textAlign: TextAlign.center,
                  color: selected ? ring : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
