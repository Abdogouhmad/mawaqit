import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/data/services/tone_preview_service.dart';
import 'package:mawaqit/data/services/alarm_service.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/widgets/update_section.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/ui/core/widgets/app_card.dart';
import 'package:mawaqit/ui/core/widgets/section_header.dart';
import 'package:mawaqit/ui/core/widgets/segmented_control.dart';
import 'package:mawaqit/ui/core/widgets/settings_row.dart';
import 'package:mawaqit/features/home/home_controller.dart';
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
        AppSpacing.xs,
        AppSpacing.xxxl,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            color: scheme.onSurfaceVariant,
            tooltip: 'Back',
          ),
          Text(
            'Settings',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
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
        AppSpacing.md,
        AppSpacing.huge,
        AppSpacing.pageBottom,
      ),
      children: [
        // Location & timing
        const SectionHeader(label: 'Location & Timing'),
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
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    settings.locationMode.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.mega),

        // Calculation
        const SectionHeader(label: 'Calculation Conventions'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                icon: Icons.calculate_outlined,
                title: 'Calculation Method',
                subtitle: settings.calculationMethod.displayName,
                onTap: () => _pickCalculationMethod(
                  context,
                  controller,
                  settings,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              SettingsRow(
                icon: Icons.balance_outlined,
                title: 'Juridical Method (Asr)',
                subtitle: settings.madhab == Madhab.hanafi
                    ? 'Hanafi'
                    : "Standard (Shafi'i, Maliki, Hanbali)",
                onTap: () => _pickMadhab(context, controller, settings),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.mega),

        // Notifications & audio
        const SectionHeader(label: 'Notifications & Audio'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pre-Prayer Alert',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: AppFontSize.lg,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    ),
                    child: Text(
                      settings.leadMinutes == 0
                          ? 'Off'
                          : '${settings.leadMinutes} min before',
                      key: ValueKey(settings.leadMinutes),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedControl<int>(
                value: settings.leadMinutes,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  controller.save(settings.copyWith(leadMinutes: value));
                },
                options: const [
                  (0, 'None'),
                  (5, '5 min'),
                  (10, '10 min'),
                  (15, '15 min'),
                ],
              ),
              const SizedBox(height: AppSpacing.huge),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              SettingsRow(
                icon: Icons.volume_up_outlined,
                title: 'Adhan Audio',
                subtitle: 'Play audio at exact prayer entry',
                onTap: () => controller.save(
                  settings.copyWith(
                    adhanSoundEnabled: !settings.adhanSoundEnabled,
                  ),
                ),
                trailing: Switch(
                  value: settings.adhanSoundEnabled,
                  onChanged: (value) => controller.save(
                    settings.copyWith(adhanSoundEnabled: value),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              SettingsRow(
                icon: Icons.music_note_outlined,
                title: 'Adhan Tone',
                subtitle: settings.adhanLabel,
                onTap: () => _openToneSheet(context, controller, settings),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              SettingsRow(
                icon: Icons.notifications_active_outlined,
                title: 'Pre-Prayer Tone',
                subtitle: settings.preAlertLabel,
                onTap: () =>
                    _openToneSheet(context, controller, settings, isAdhan: false),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              SettingsRow(
                icon: Icons.campaign_outlined,
                title: 'Test Notification',
                subtitle: 'Fires the adhan alarm in 3 seconds',
                onTap: () => _sendTestNotification(context, ref),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              SettingsRow(
                icon: Icons.verified_user_outlined,
                title: 'Notification Permission',
                subtitle: 'Re-ask for notifications & exact alarms',
                onTap: () => _requestPermissions(context, ref),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: AppIconSize.xl,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.mega),

        // Appearance
        const SectionHeader(label: 'Appearance'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: AppFontSize.lg,
                    ),
                  ),
                  Text(
                    'Automatic match',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedControl<AppThemeMode>(
                value: settings.themeMode,
                onChanged: (value) => controller.save(
                  settings.copyWith(themeMode: value),
                ),
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.tera),

        // About & OTA updates
        const SectionHeader(label: 'About & Update'),
        const UpdateSection(),
        const SizedBox(height: AppSpacing.tera),
        _Footer(),
      ],
    );
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(notificationServiceProvider);
    final homeState = ref.read(homeControllerProvider).value;
    try {
      await service.init();
      final scheduled = defaultTargetPlatform == TargetPlatform.android
          // Screen-off path: an exact RTC_WAKEUP alarm fires the adhan alert in
          // a background isolate, so the test works with the display off.
          ? await AlarmService.scheduleTest()
          : await service.scheduleTestNotification(
              settings: settings,
              day: homeState?.day,
            );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            scheduled
                ? 'Adhan alarm fired — check the tray and lockscreen.'
                : 'Notifications are off — re-enable them via '
                    '"Notification Permission" below.',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Test notification failed: $e\n$st'),
        ),
      );
    }
  }

  Future<void> _requestPermissions(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
      label: (m) => m == Madhab.hanafi
          ? 'Hanafi'
          : "Standard (Shafi'i, Maliki, Hanbali)",
      current: settings.madhab,
    );
    if (selected != null) {
      await controller.save(settings.copyWith(madhab: selected));
    }
  }

  void _openToneSheet(
    BuildContext context,
    SettingsController controller,
    AppSettings settings, {
    bool isAdhan = true,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ToneSheet(
        controller: controller,
        initialSettings: settings,
        isAdhan: isAdhan,
      ),
    );
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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    selectedTileColor:
                        scheme.primary.withValues(alpha: 0.06),
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
              onChanged: (mode) => setState(
                () => _draft = _draft.copyWith(locationMode: mode),
              ),
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
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ] else if (!_searched &&
                  query.length < 3 &&
                  _results.isEmpty &&
                  _error == null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Type at least 3 characters to search.',
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
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
                            color: scheme.outlineVariant
                                .withValues(alpha: 0.4),
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
                          selectedTileColor:
                              scheme.primary.withValues(alpha: 0.06),
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

class _ToneSheet extends StatefulWidget {
  const _ToneSheet({
    required this.controller,
    required this.initialSettings,
    this.isAdhan = true,
  });

  final SettingsController controller;
  final AppSettings initialSettings;

  /// When true the sheet picks the adhan tone; otherwise the pre-prayer tone.
  final bool isAdhan;

  @override
  State<_ToneSheet> createState() => _ToneSheetState();
}

class _ToneSheetState extends State<_ToneSheet> {
  final TonePreviewService _preview = TonePreviewService();
  String? _playing;

  bool get _isAdhan => widget.isAdhan;

  List<AdhanTone> get _tones =>
      _isAdhan ? ToneCatalog.tones : ToneCatalog.preAlertTones;

  @override
  void initState() {
    super.initState();
    _preview.onComplete = () {
      if (mounted) setState(() => _playing = null);
    };
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(AdhanTone tone) async {
    HapticFeedback.selectionClick();
    final ok = await _preview.toggle(tone);
    if (!mounted) return;
    setState(() => _playing = ok ? _preview.playing : null);
    if (!ok) _showUnavailable();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview unavailable on this device.')),
    );
  }

  void _select(AppSettings updated) {
    HapticFeedback.selectionClick();
    widget.controller.save(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = widget.initialSettings;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.huge,
          right: AppSpacing.huge,
          top: AppSpacing.md,
          bottom: AppSpacing.giga,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isAdhan ? 'Adhan Tone' : 'Pre-Prayer Tone',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the speaker to preview a sound before choosing.',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _sectionLabel(context, 'Built-in tones'),
            const SizedBox(height: AppSpacing.sm),
            _card(
              context,
              [
                for (final (index, tone) in _tones.indexed)
                  _tile(
                    context,
                    first: index == 0,
                    title: tone.name,
                    subtitle: tone.silent
                        ? 'No sound'
                        : (_preview.isSupported
                              ? 'Tap to preview'
                              : 'Preview unavailable'),
                    selected: _isAdhan
                        ? !settings.usesDeviceTone &&
                            settings.adhanTone == tone.name
                        : settings.preAlertTone == tone.name,
                    leading: tone.silent
                        ? Icon(
                            Icons.volume_off_outlined,
                            color: scheme.onSurfaceVariant,
                          )
                        : _previewButton(
                            context,
                            enabled: _preview.isSupported,
                            playing: _playing == tone.name,
                            onPressed: () => _togglePreview(tone),
                          ),
                    onTap: () => _select(
                      _isAdhan
                          ? settings.withBundledTone(tone.name)
                          : settings.withPreAlertTone(tone.name),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(
    BuildContext context, {
    required bool first,
    required String title,
    required String subtitle,
    required bool selected,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (!first)
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          leading: leading,
          trailing: selected
              ? Icon(
                  Icons.check_circle,
                  color: scheme.primary,
                  size: AppIconSize.xl,
                )
              : null,
          selected: selected,
          selectedTileColor: scheme.primary.withValues(alpha: 0.06),
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _previewButton(
    BuildContext context, {
    required bool enabled,
    required bool playing,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: enabled ? 'Preview' : 'Preview unavailable',
      icon: Icon(
        playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
        color: enabled
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: AppIconSize.xs,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Mawaqit • No accounts, no tracking.',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Version ${AppInfo.version}',
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            letterSpacing: 0.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}