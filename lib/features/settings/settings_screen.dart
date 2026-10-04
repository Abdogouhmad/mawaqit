import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/motion.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/widgets/alarm_access_section.dart';
import 'package:mawaqit/features/settings/widgets/notification_settings_section.dart';
import 'package:mawaqit/features/settings/widgets/update_section.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/shared/ui/option_sheet.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/l10n/enum_localization.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: asyncSettings.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: UiText(error.toString(), textAlign: TextAlign.center),
                ),
                data: (settings) => _SettingsBody(settings: settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // No back arrow and no Done button.
    //
    // Settings is a tab in the bottom shell, not a pushed route, so there is
    // nothing to pop back to: both controls ran `Navigator.maybePop()`, which on
    // a tab root does nothing at all and leaves the button looking broken. The
    // tab bar is the way out, and the Android system back gesture behaves the
    // same way.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(
            AppLocalizations.of(context).settingsTitle,
            type: UiTextType.titleLarge,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          const SizedBox(height: AppSpacing.xxs),
          UiText(
            AppLocalizations.of(context).settingsSubtitle,
            type: UiTextType.labelMedium,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return NavVisibilityScope.wrap(
      context,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.huge,
          AppSpacing.xs,
          AppSpacing.huge,
          AppSpacing.pageBottom,
        ),
        children: [
          // Location & timing
          SectionHeader(
            label: AppLocalizations.of(context).settingsSectionLocationTiming,
            description: l10n.settingsLocationTimingDesc,
            icon: Icons.near_me_outlined,
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: SettingsRow(
              icon: Icons.near_me_outlined,
              title: AppLocalizations.of(context).settingsCurrentLocation,
              subtitle: _locationSubtitle(context, settings),
              onTap: () =>
                  _openLocationSheet(context, ref, controller, settings),
              trailing: AppPill(
                label: settings.locationMode.localized(l10n),
                dense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.mega),

          // Calculation
          SectionHeader(
            label: AppLocalizations.of(context).settingsSectionCalculation,
            description: l10n.settingsCalculationDesc,
            icon: Icons.calculate_outlined,
          ),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.calculate_outlined,
                title: AppLocalizations.of(context).settingsCalculationMethod,
                subtitle: settings.calculationMethod.displayName,
                onTap: () =>
                    _pickCalculationMethod(context, controller, settings),
                trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
              ),
              SettingsRow(
                icon: Icons.balance_outlined,
                title: l10n.settingsJuridicalMethod,
                subtitle: settings.madhab == Madhab.hanafi
                    ? l10n.madhabHanafi
                    : l10n.madhabStandard,
                onTap: () => _pickMadhab(context, controller, settings),
                trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.mega),

          // Notifications & audio
          SectionHeader(
            label: AppLocalizations.of(context).settingsSectionNotifications,
            description: l10n.settingsNotificationsDesc,
            icon: Icons.notifications_none,
          ),
          SettingsGroup(
            children: [
              NotificationSettingsSection(kind: NotificationKind.prePrayer),
              NotificationSettingsSection(kind: NotificationKind.adhan),
            ],
          ),
          const SizedBox(height: AppSpacing.huge),
          const AlarmAccessSection(),
          const SizedBox(height: AppSpacing.mega),

          // Appearance
          SectionHeader(
            label: AppLocalizations.of(context).settingsSectionAppearance,
            description: l10n.settingsAppearanceDesc,
            icon: Icons.palette_outlined,
          ),
          SettingsGroup(
            children: [
              _SegmentedSettingRow<AppLanguage>(
                icon: Icons.language,
                title: l10n.settingsLanguage,
                valueLabel: settings.language.localized(l10n),
                control: SegmentedControl<AppLanguage>(
                  value: settings.language,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    controller.save(settings.copyWith(language: value));
                  },
                  icons: const [
                    Icons.settings_suggest_outlined,
                    Icons.abc_outlined,
                    Icons.text_fields,
                    Icons.translate,
                  ],
                  options: [
                    (AppLanguage.system, l10n.settingsLanguageSystem),
                    (AppLanguage.english, l10n.settingsLanguageEnglish),
                    (AppLanguage.arabic, l10n.settingsLanguageArabic),
                    (AppLanguage.french, l10n.settingsLanguageFrench),
                  ],
                ),
              ),
              _SegmentedSettingRow<AppThemeMode>(
                icon: Icons.palette_outlined,
                title: l10n.settingsTheme,
                valueLabel: _themeLabel(context, settings.themeMode),
                control: SegmentedControl<AppThemeMode>(
                  value: settings.themeMode,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    controller.save(settings.copyWith(themeMode: value));
                  },
                  icons: const [
                    Icons.settings_brightness,
                    Icons.light_mode_outlined,
                    Icons.dark_mode_outlined,
                  ],
                  options: [
                    (AppThemeMode.system, l10n.settingsThemeSystem),
                    (AppThemeMode.light, l10n.settingsThemeLight),
                    (AppThemeMode.dark, l10n.settingsThemeDark),
                  ],
                ),
              ),
              _PaletteSettingRow(
                value: settings.palette,
                onChanged: (palette) {
                  HapticFeedback.selectionClick();
                  controller.save(settings.copyWith(palette: palette));
                },
              ),
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
            ],
          ),
          const SizedBox(height: AppSpacing.tera),

          // About & OTA updates
          SectionHeader(
            label: AppLocalizations.of(context).settingsSectionAbout,
            icon: Icons.info_outline,
          ),
          const UpdateSection(),
          const SizedBox(height: AppSpacing.tera),
          const _Footer(),
        ],
      ),
    );
  }

  String _locationSubtitle(BuildContext context, AppSettings settings) {
    if (settings.locationMode == LocationMode.city &&
        settings.hasCityCoordinates) {
      return '${settings.cityName} · ${settings.cityLatitude!.toStringAsFixed(2)}, '
          '${settings.cityLongitude!.toStringAsFixed(2)}';
    }
    return AppLocalizations.of(context).settingsAutoGpsValue;
  }

  String _themeLabel(BuildContext context, AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => AppLocalizations.of(
      context,
    ).settingsThemeSystemValue,
    AppThemeMode.light => AppLocalizations.of(context).settingsThemeLight,
    AppThemeMode.dark => AppLocalizations.of(context).settingsThemeDark,
  };

  void _openLocationSheet(
    BuildContext context,
    WidgetRef ref,
    SettingsController controller,
    AppSettings settings,
  ) {
    final locationRepo = ref.read(locationRepositoryProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LocationSheet(
        repository: locationRepo,
        controller: controller,
        initialSettings: settings,
      ),
    );
  }

  Future<void> _pickCalculationMethod(
    BuildContext context,
    SettingsController controller,
    AppSettings settings,
  ) async {
    const methods = [
      CalculationMethod.muslimWorldLeague,
      CalculationMethod.northAmerica,
      CalculationMethod.ummAlQura,
      CalculationMethod.egyptian,
      CalculationMethod.karachi,
      CalculationMethod.turkiye,
      CalculationMethod.morocco,
      CalculationMethod.france,
      CalculationMethod.gulfRegion,
      CalculationMethod.kuwait,
      CalculationMethod.qatar,
      CalculationMethod.singapore,
      CalculationMethod.indonesian,
      CalculationMethod.russia,
      CalculationMethod.tehran,
      CalculationMethod.jafari,
    ];
    final selected = await showOptionSheet<CalculationMethod>(
      context: context,
      title: AppLocalizations.of(context).settingsCalculationMethod,
      options: methods,
      label: (m) => m.displayName,
      current: settings.calculationMethod,
    );
    if (selected != null) {
      await controller.save(settings.copyWith(calculationMethod: selected));
    }
  }

  Future<void> _pickMadhab(
    BuildContext context,
    SettingsController controller,
    AppSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showOptionSheet<Madhab>(
      context: context,
      title: l10n.settingsJuridicalMethod,
      options: Madhab.values,
      label: (m) =>
          m == Madhab.hanafi ? l10n.madhabHanafi : l10n.madhabStandard,
      current: settings.madhab,
    );
    if (selected != null) {
      await controller.save(settings.copyWith(madhab: selected));
    }
  }
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({
    required this.repository,
    required this.controller,
    required this.initialSettings,
  });

  final LocationRepository repository;
  final SettingsController controller;
  final AppSettings initialSettings;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initialSettings.cityName ?? '',
  );
  late AppSettings _draft = widget.initialSettings;
  List<CitySearchResult> _results = const [];
  bool _searching = false;
  bool _searched = false;
  String? _error;
  Timer? _debounce;
  int _searchId = 0;

  /// `AppLocalizations.of` is a `Localizations.of` lookup under the hood, so
  /// the async debounced search path can read it without a context of its own.
  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!mounted) return;
    final query = _queryController.text.trim();
    if (query.length < 3) {
      setState(() {
        _searching = false;
        _searched = false;
        _results = const [];
        _error = null;
      });
      return;
    }
    final id = ++_searchId;
    setState(() {
      _searching = true;
      _searched = true;
      _results = const [];
      _error = null;
    });
    List<CitySearchResult> found;
    try {
      found = await widget.repository.searchCities(query);
    } catch (e) {
      if (!mounted || id != _searchId) return;
      setState(() {
        _searching = false;
        _error = l10n.settingsSearchFailed(e);
      });
      return;
    }
    if (!mounted || id != _searchId) return;
    setState(() {
      _searching = false;
      _results = found;
      _error = found.isEmpty ? l10n.settingsNoCityFound(query) : null;
    });
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _search);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final query = _queryController.text.trim();
    final city = _draft.locationMode == LocationMode.city;
    final canSave = !city || _draft.hasCityCoordinates;

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          left: AppSpacing.huge,
          right: AppSpacing.huge,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.giga,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiText(l10n.settingsLocationTitle, type: UiTextType.titleLarge),
            const SizedBox(height: AppSpacing.xxxl),
            SegmentedControl<LocationMode>(
              value: _draft.locationMode,
              onChanged: (mode) =>
                  setState(() => _draft = _draft.copyWith(locationMode: mode)),
              options: [
                (LocationMode.autoGps, l10n.settingsLocationModeAuto),
                (LocationMode.city, l10n.settingsLocationModeCity),
              ],
            ),
            if (city) ...[
              const SizedBox(height: AppSpacing.xxxl),
              TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                autofocus: true,
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _search();
                },
                decoration: InputDecoration(
                  labelText: l10n.settingsCityName,
                  hintText: AppLocalizations.of(context).settingsCitySearchHint,
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: SizedBox(
                            width: AppIconSize.xl,
                            height: AppIconSize.xl,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _debounce?.cancel();
                            _search();
                          },
                        ),
                ),
              ),
              if (_searching) ...[
                const SizedBox(height: AppSpacing.lg),
                UiText(
                  l10n.settingsSearching,
                  type: UiTextType.labelMedium,
                  color: scheme.onSurfaceVariant,
                ),
              ] else if (!_searched &&
                  query.length < 3 &&
                  _results.isEmpty &&
                  _error == null) ...[
                const SizedBox(height: AppSpacing.lg),
                UiText(
                  l10n.settingsSearchMinChars,
                  type: UiTextType.labelMedium,
                  color: scheme.onSurfaceVariant,
                ),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: EdgeInsets.zero,
                  radius: AppRadius.md,
                  borderColor: scheme.outlineVariant.withValues(alpha: 0.4),
                  ambient: false,
                  child: Column(
                    children: [
                      for (final (index, result) in _results.indexed) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ListTile(
                          dense: true,
                          title: UiText(
                            result.name,
                            type: UiTextType.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: UiText(
                            l10n.settingsCoordinates(
                              result.latitude.toStringAsFixed(3),
                              result.longitude.toStringAsFixed(3),
                            ),
                            type: UiTextType.bodyMedium,
                          ),
                          trailing: _draft.cityName == result.name
                              ? Icon(
                                  Icons.check_circle,
                                  color: scheme.primary,
                                  size: AppIconSize.xl,
                                )
                              : null,
                          selected: _draft.cityName == result.name,
                          selectedTileColor: scheme.primary.withValues(
                            alpha: 0.06,
                          ),
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              locationMode: LocationMode.city,
                              cityName: result.name,
                              cityLatitude: result.latitude,
                              cityLongitude: result.longitude,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                UiText(
                  _error!,
                  type: UiTextType.labelMedium,
                  color: scheme.error,
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.huge),
            AppButton(
              label: l10n.actionSaveLocation,
              icon: Icons.check_rounded,
              onPressed: canSave
                  ? () {
                      widget.controller.save(_draft);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + current value + a segmented control, the shape both Appearance rows
/// share. Extracted so the language and theme rows cannot drift apart.
class _SegmentedSettingRow<T> extends StatelessWidget {
  const _SegmentedSettingRow({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.control,
  });

  final IconData icon;
  final String title;
  final String valueLabel;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: icon),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      title,
                      type: UiTextType.titleMedium,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    UiText(
                      valueLabel,
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
          control,
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Icon(
          Icons.timelapse_outlined,
          color: scheme.primary.withValues(alpha: 0.45),
        ),
        const SizedBox(height: AppSpacing.md),
        UiText(
          l10n.appTitle,
          type: UiTextType.titleMedium,
          fontWeight: FontWeight.w700,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        UiText(
          l10n.settingsAboutTagline,
          type: UiTextType.labelMedium,
          color: scheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        // The localized template, not the English literal this used to spell
        // out — that string is exactly `settingsAboutVersion`'s en value, so
        // Arabic and French readers were seeing English here while the About
        // dialog above them was translated.
        UiText(
          l10n.settingsAboutVersion(AppInfo.version),
          type: UiTextType.labelSmall,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Palette picker.
///
/// Rendered as swatch circles rather than a segmented control of words: the
/// three palettes differ in *colour*, not in meaning, so the control should
/// show the thing being chosen. Names stay as the semantic label so a screen
/// reader announces what the swatch is.
///
/// Deliberately separate from `_SegmentedSettingRow` — that one is a text
/// control for text-valued settings, and reusing it here would mean inventing
/// an icon list whose icons do not correspond to anything.
class _PaletteSettingRow extends StatelessWidget {
  const _PaletteSettingRow({required this.value, required this.onChanged});

  final AppPalette value;
  final ValueChanged<AppPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
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
                      _labelOf(value, l10n),
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
          Row(
            children: [
              for (final palette in AppPalette.values)
                Expanded(
                  child: _PaletteSwatch(
                    palette: palette,
                    selected: palette == value,
                    label: _labelOf(palette, l10n),
                    onTap: () => onChanged(palette),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _labelOf(AppPalette palette, AppLocalizations l10n) =>
      switch (palette) {
        AppPalette.emerald => l10n.appearancePaletteEmerald,
        AppPalette.sage => l10n.appearancePaletteSage,
        AppPalette.midnight => l10n.appearancePaletteMidnight,
      };
}

/// One selectable palette swatch: a two-tone dot showing the palette's primary
/// over its surface, with a ring when selected.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Resolved from the seed rather than read off the live [scheme], so each
    // swatch previews the palette it selects — including the two the user is not
    // currently on, which is the whole point of a picker.
    final preview = ColorScheme.fromSeed(
      seedColor: palette.lightSeed,
      brightness: Theme.of(context).brightness,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // The dot is decoration as far as assistive tech is concerned; the label
      // above already carries the name.
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                height: AppSpacing.control,
                width: AppSpacing.control,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Two arcs rather than a flat fill: the palette is defined by
                  // its primary/secondary pair, and a single-colour dot would
                  // make Emerald and Sage nearly indistinguishable at 40 dp.
                  gradient: SweepGradient(
                    colors: [
                      preview.primary,
                      preview.secondary,
                      preview.primary,
                    ],
                  ),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              UiText(
                label,
                type: UiTextType.labelSmall,
                textAlign: TextAlign.center,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
