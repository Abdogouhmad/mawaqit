import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/widgets/notification_settings_section.dart';
import 'package:mawaqit/features/settings/widgets/update_section.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/widgets/app_card.dart';
import 'package:mawaqit/shared/widgets/section_header.dart';
import 'package:mawaqit/shared/widgets/segmented_control.dart';
import 'package:mawaqit/shared/widgets/settings_group.dart';
import 'package:mawaqit/shared/widgets/settings_row.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';

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
                error: (error, _) => Center(child: Text(error.toString())),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Material(
            color: scheme.secondaryContainer.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              color: scheme.onSecondaryContainer,
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Prayer times, reminders & appearance',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              'Done',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.huge,
        AppSpacing.xs,
        AppSpacing.huge,
        AppSpacing.pageBottom,
      ),
      children: [
        // Location & timing
        const SectionHeader(
          label: 'Location & Timing',
          description: 'Where prayer times are computed for',
          icon: Icons.near_me_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: SettingsRow(
            icon: Icons.near_me_outlined,
            title: 'Current Location',
            subtitle: _locationSubtitle(settings),
            onTap: () => _openLocationSheet(context, ref, controller, settings),
            trailing: _StatusPill(label: settings.locationMode.label),
          ),
        ),
        const SizedBox(height: AppSpacing.mega),

        // Calculation
        const SectionHeader(
          label: 'Calculation Conventions',
          description: 'Method & Asr jurisprudence for the day',
          icon: Icons.calculate_outlined,
        ),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.calculate_outlined,
              title: 'Calculation Method',
              subtitle: settings.calculationMethod.displayName,
              onTap: () =>
                  _pickCalculationMethod(context, controller, settings),
              trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
            ),
            SettingsRow(
              icon: Icons.balance_outlined,
              title: 'Juridical Method (Asr)',
              subtitle: settings.madhab == Madhab.hanafi
                  ? 'Hanafi'
                  : "Standard (Shafi'i, Maliki, Hanbali)",
              onTap: () => _pickMadhab(context, controller, settings),
              trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.mega),

        // Notifications & audio
        const SectionHeader(
          label: 'Notifications & Alerts',
          description: 'Rings the adhan and pre-prayer countdowns',
          icon: Icons.notifications_none,
        ),
        SettingsGroup(
          children: [
            NotificationSettingsSection(kind: NotificationKind.prePrayer),
            NotificationSettingsSection(kind: NotificationKind.adhan),
            SettingsRow(
              icon: Icons.verified_user_outlined,
              title: 'Notification Permission',
              subtitle: 'Notifications, exact alarms & full-screen wake access',
              onTap: () => _requestPermissions(context, ref),
              trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.mega),

        // Appearance
        const SectionHeader(
          label: 'Appearance',
          description: 'Follow the phone or pick a fixed theme',
          icon: Icons.palette_outlined,
        ),
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.xxl,
                AppSpacing.xxxl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  _LeadingIcon(Icons.palette_outlined),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _themeLabel(settings.themeMode),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                0,
                AppSpacing.xxxl,
                AppSpacing.xxl,
              ),
              child: SegmentedControl<AppThemeMode>(
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
                options: const [
                  (AppThemeMode.system, 'System'),
                  (AppThemeMode.light, 'Light'),
                  (AppThemeMode.dark, 'Dark'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.tera),

        // About & OTA updates
        const SectionHeader(label: 'About & Update', icon: Icons.info_outline),
        const UpdateSection(),
        const SizedBox(height: AppSpacing.tera),
        _Footer(),
      ],
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(notificationServiceProvider);
    try {
      final granted = await service.ensurePermissions();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Permissions OK — notifications enabled.'
                : 'Permission denied — enable notifications in system '
                      'settings, then tap again.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not request permissions.')),
      );
    }
  }

  String _locationSubtitle(AppSettings settings) {
    if (settings.locationMode == LocationMode.city &&
        settings.hasCityCoordinates) {
      return '${settings.cityName} · ${settings.cityLatitude!.toStringAsFixed(2)}, '
          '${settings.cityLongitude!.toStringAsFixed(2)}';
    }
    return 'Automatic (GPS)';
  }

  String _themeLabel(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => 'Follows the phone',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
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
    final selected = await _showOptionSheet<CalculationMethod>(
      context,
      title: 'Calculation Method',
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
    final selected = await _showOptionSheet<Madhab>(
      context,
      title: 'Juridical Method (Asr)',
      options: Madhab.values,
      label: (m) =>
          m == Madhab.hanafi ? 'Hanafi' : "Standard (Shafi'i, Maliki, Hanbali)",
      current: settings.madhab,
    );
    if (selected != null) {
      await controller.save(settings.copyWith(madhab: selected));
    }
  }

  Future<T?> _showOptionSheet<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) label,
    required T current,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.giga,
                AppSpacing.xs,
                AppSpacing.giga,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == current;
                  return ListTile(
                    title: Text(label(option)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            size: AppIconSize.xl,
                            color: scheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    selectedTileColor: scheme.primary.withValues(alpha: 0.06),
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
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
        _error = 'Search failed: $e';
      });
      return;
    }
    if (!mounted || id != _searchId) return;
    setState(() {
      _searching = false;
      _results = found;
      _error = found.isEmpty
          ? 'No city found for "$query". Try a larger area.'
          : null;
    });
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _search);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            Text('Location', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxxl),
            SegmentedControl<LocationMode>(
              value: _draft.locationMode,
              onChanged: (mode) =>
                  setState(() => _draft = _draft.copyWith(locationMode: mode)),
              options: const [
                (LocationMode.autoGps, 'Auto (GPS)'),
                (LocationMode.city, 'City'),
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
                  labelText: 'City name',
                  hintText: 'e.g. London or Casablanca',
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
                Text(
                  'Searching…',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ] else if (!_searched &&
                  query.length < 3 &&
                  _results.isEmpty &&
                  _error == null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Type at least 3 characters to search.',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Material(
                  color: scheme.surfaceContainerLowest,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
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
                          title: Text(
                            result.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${result.latitude.toStringAsFixed(3)}, '
                            '${result.longitude.toStringAsFixed(3)}',
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
                Text(
                  _error!,
                  style: textTheme.labelMedium?.copyWith(color: scheme.error),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.huge),
            FilledButton(
              onPressed: canSave
                  ? () {
                      widget.controller.save(_draft);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('Save location'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leading icon circle reused by non-tappable group headers (matches
/// `SettingsRow`'s own tile icon so rows stay visually aligned).
class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSpacing.control,
      height: AppSpacing.control,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
      ),
      child: Icon(
        icon,
        size: AppIconSize.lg,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

/// Quiet status pill (e.g. the active location mode) ending a settings row.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          '◷',
          style: textTheme.headlineSmall?.copyWith(
            color: scheme.primary.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Mawaqit',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Prayer times, without the noise.',
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'v${AppInfo.version}  •  No accounts, no tracking',
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            letterSpacing: 0.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
