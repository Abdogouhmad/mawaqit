import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/navigation/app_shell.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/features/settings/screen/general.dart';
import 'package:mawaqit/features/settings/screen/notify.dart';
import 'package:mawaqit/features/settings/screen/permission.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/features/settings/widgets/update_section.dart';
import 'package:mawaqit/l10n/enum_localization.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/option_sheet.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

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

          // General
          SectionHeader(
            label: l10n.settingsSectionGeneral,
            description: l10n.settingsGeneralDesc,
            icon: Icons.tune,
          ),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.tune,
                title: l10n.settingsGeneralRow,
                subtitle:
                    '${settings.language.localized(l10n)} · '
                    '${settings.themeMode.localized(l10n)}',
                onTap: () => _openGeneral(context),
                trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.mega),

          // Notifications & audio
          SectionHeader(
            label: l10n.settingsSectionNotifications,
            description: l10n.settingsNotificationsDesc,
            icon: Icons.notifications_none,
          ),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.notifications_none,
                title: l10n.settingsNotificationsRow,
                subtitle: l10n.settingsNotificationsDesc,
                onTap: () => _openNotifications(context),
                trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.mega),

          // Permissions
          SectionHeader(
            label: l10n.settingsSectionPermissions,
            description: l10n.settingsPermissionsDesc,
            icon: Icons.verified_user_outlined,
          ),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.verified_user_outlined,
                title: l10n.settingsPermissionsRow,
                subtitle: l10n.settingsPermissionsDesc,
                onTap: () => _openPermissions(context),
                trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
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

  void _openGeneral(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GeneralScreen()));
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openPermissions(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PermissionsScreen()));
  }

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
