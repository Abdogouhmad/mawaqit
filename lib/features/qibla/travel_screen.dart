import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/repositories/location_repository.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/providers/providers.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Temporary travel location.
///
/// The override lives in [AppSettings.travelName]/coordinates and never touches
/// the saved home city or the GPS cache. Returning home is a single settings
/// write; no permission is requested and nothing is tracked in the background.
class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<CitySearchResult> _results = const [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 3) {
      setState(() {
        _searching = false;
        _results = const [];
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _results = const [];
      _error = null;
    });
    try {
      final found = await ref
          .read(locationRepositoryProvider)
          .searchCities(query);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = found;
        _error = found.isEmpty
            ? AppLocalizations.of(context).travelNoResults
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = AppLocalizations.of(context).settingsSearchFailed(error);
      });
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(AppMotion.long, _search);
  }

  Future<void> _setTravel(CitySearchResult city) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    await ref
        .read(settingsProvider.notifier)
        .save(
          settings.withTravel(
            name: city.name,
            latitude: city.latitude,
            longitude: city.longitude,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _returnHome() async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    await ref.read(settingsProvider.notifier).save(settings.clearTravel());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider).value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.travelTitle,
          type: UiTextType.titleLarge,
          fontWeight: AppWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.huge,
            AppSpacing.sm,
            AppSpacing.huge,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                label: l10n.travelTitle,
                description: l10n.travelDesc,
                icon: Icons.flight_takeoff_outlined,
              ),
              if (settings?.isTraveling ?? false) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        l10n.travelActive(settings!.travelName ?? ''),
                        type: UiTextType.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      UiText(
                        l10n.travelCalculationMethod(
                          settings.calculationMethod.displayName,
                        ),
                        type: UiTextType.labelMedium,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: l10n.travelReturn,
                        icon: Icons.home_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: _returnHome,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.giga),
              ],
              UiText(l10n.travelSetLocation, type: UiTextType.titleSmall),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _search();
                },
                decoration: InputDecoration(
                  labelText: l10n.travelSearchHint,
                  hintText: l10n.travelSearchHint,
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: SizedBox(
                            width: AppIconSize.xl,
                            height: AppIconSize.xl,
                            child: CircularProgressIndicator(
                              strokeWidth: AppStroke.focus,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: l10n.travelSearchHint,
                          onPressed: () {
                            _debounce?.cancel();
                            _search();
                          },
                        ),
                ),
              ),
              if (_error != null || _searching) ...[
                const SizedBox(height: AppSpacing.lg),
                // TalkBack announces the outcome of the search without the
                // user having to hunt for the message below the field.
                Semantics(
                  liveRegion: true,
                  child: UiText(
                    _error ?? l10n.travelSearching,
                    type: UiTextType.labelMedium,
                    color: _error != null
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: EdgeInsets.zero,
                  borderColor: scheme.outlineVariant.withValues(
                    alpha: AppOpacity.hairline,
                  ),
                  ambient: false,
                  child: Column(
                    children: [
                      for (final (index, result) in _results.indexed) ...[
                        if (index > 0)
                          Divider(
                            height: AppStroke.hairline,
                            color: scheme.outlineVariant.withValues(
                              alpha: AppOpacity.hairline,
                            ),
                          ),
                        ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_city_outlined,
                            size: AppIconSize.xl,
                            color: scheme.onSurfaceVariant,
                          ),
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
                          onTap: () => _setTravel(result),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
