import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/audio/tone_catalog.dart';
import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/models/notification_kind.dart';
import 'package:mawaqit/data/services/tone_preview_service.dart';
import 'package:mawaqit/features/settings/settings_controller.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/l10n/enum_localization.dart';

/// Bottom-sheet tone picker shared by the Pre-Prayer and Adhan notification
/// settings. Parameterized by [kind] so both sections reuse the exact same
/// picker without duplicating any logic.
class ToneSheet extends StatefulWidget {
  const ToneSheet({
    super.key,
    required this.controller,
    required this.initialSettings,
    required this.kind,
  });

  final SettingsController controller;
  final AppSettings initialSettings;
  final NotificationKind kind;

  @override
  State<ToneSheet> createState() => _ToneSheetState();
}

class _ToneSheetState extends State<ToneSheet> {
  final TonePreviewService _preview = TonePreviewService();

  /// Which entry is previewing, keyed so a bundled tone and a device sound
  /// that happen to share a name can't toggle each other. Null when silent.
  String? _playing;

  /// Device sounds, read once from the platform on first open. Null means "not
  /// loaded yet" (the sheet shows a spinner), an empty list means "loaded and
  /// the device genuinely has none to offer".
  List<DeviceTone>? _deviceTones;
  bool _deviceTonesFailed = false;

  NotificationKind get _kind => widget.kind;

  List<AdhanTone> get _tones => _kind == NotificationKind.adhan
      ? ToneCatalog.tones
      : ToneCatalog.preAlertTones;

  /// Device ringtones only apply to the adhan: a pre-prayer alert is a short
  /// chime played from a notification channel, and a device ringtone is
  /// frequently long enough to still be ringing when the adhan starts.
  bool get _showsDeviceSection =>
      _kind == NotificationKind.adhan && _preview.supportsDeviceTones;

  @override
  void initState() {
    super.initState();
    _preview.onComplete = () {
      if (mounted) setState(() => _playing = null);
    };
    if (_showsDeviceSection) unawaited(_loadDeviceTones());
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceTones() async {
    final tones = await _preview.listDeviceTones();
    // The sheet can be dismissed while the platform call is in flight.
    if (!mounted) return;
    setState(() {
      _deviceTones = tones;
      _deviceTonesFailed = false;
    });
  }

  String _builtinKey(AdhanTone tone) => 'builtin:${tone.name}';
  String _deviceKey(DeviceTone tone) => 'device:${tone.uri}';

  Future<void> _togglePreview(AdhanTone tone) async {
    HapticFeedback.selectionClick();
    final key = _builtinKey(tone);
    if (_playing == key) {
      await _preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    final ok = await _preview.play(tone);
    if (!mounted) return;
    setState(() => _playing = ok ? key : null);
    if (!ok) _showUnavailable();
  }

  Future<void> _toggleDevicePreview(DeviceTone tone) async {
    HapticFeedback.selectionClick();
    final key = _deviceKey(tone);
    if (_playing == key) {
      await _preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    final ok = await _preview.previewDeviceTone(tone);
    if (!mounted) return;
    setState(() => _playing = ok ? key : null);
    if (!ok) _showUnavailable();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).toneSheetPreviewUnavailable),
      ),
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
            UiText(
              AppLocalizations.of(
                context,
              ).notifToneTitle(_kind.localized(AppLocalizations.of(context))),
              type: UiTextType.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            UiText(
              AppLocalizations.of(context).toneSheetPreviewHint,
              type: UiTextType.labelMedium,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _sectionLabel(
              context,
              AppLocalizations.of(context).toneSheetBuiltIn,
            ),
            const SizedBox(height: AppSpacing.sm),
            _card(context, [
              for (final (index, tone) in _tones.indexed)
                _tile(
                  context,
                  first: index == 0,
                  title: tone.name,
                  subtitle: tone.silent
                      ? AppLocalizations.of(context).toneSheetNoSound
                      : (_preview.isSupported
                            ? AppLocalizations.of(context).toneSheetTapToPreview
                            : AppLocalizations.of(context)
                                  .toneSheetPreviewUnavailableShort),
                  selected: _selected(settings, tone),
                  leading: tone.silent
                      ? Icon(
                          Icons.volume_off_outlined,
                          color: scheme.onSurfaceVariant,
                        )
                      : _previewButton(
                          context,
                          enabled: _preview.isSupported,
                          playing: _playing == _builtinKey(tone),
                          onPressed: () => _togglePreview(tone),
                        ),
                  onTap: () => _select(
                    _kind == NotificationKind.adhan
                        ? settings.withBundledTone(tone.name)
                        : settings.withPreAlertTone(tone.name),
                  ),
                ),
            ]),
            if (_showsDeviceSection) ...[
              const SizedBox(height: AppSpacing.xxl),
              _sectionLabel(
                context,
                AppLocalizations.of(context).toneSheetDeviceSounds,
              ),
              const SizedBox(height: AppSpacing.sm),
              _deviceSection(context, settings),
              const SizedBox(height: AppSpacing.sm),
              UiText(
                AppLocalizations.of(context).toneSheetDeviceNote,
                type: UiTextType.labelMedium,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The device-sound list, or whatever is known about it so far: a spinner
  /// while the platform read is in flight, a retryable row if it failed, and an
  /// explanatory row when the device genuinely exposes no sounds.
  Widget _deviceSection(BuildContext context, AppSettings settings) {
    final tones = _deviceTones;
    if (tones == null) {
      return _card(context, [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.md),
              UiText(
                AppLocalizations.of(context).toneSheetReading,
                type: UiTextType.bodyMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ]);
    }

    if (tones.isEmpty) {
      return _card(context, [
        _messageRow(
          context,
          icon: Icons.phone_android_outlined,
          message: _deviceTonesFailed
              ? AppLocalizations.of(context).toneSheetReadFailed
              : AppLocalizations.of(context).toneSheetUnavailable,
          action: _deviceTonesFailed
              ? ListTile(
                  title: UiText(
                    AppLocalizations.of(context).actionTryAgain,
                    type: UiTextType.bodyLarge,
                  ),
                  trailing: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                    size: AppIconSize.xl,
                  ),
                  onTap: () {
                    setState(() {
                      _deviceTones = null;
                      _deviceTonesFailed = false;
                    });
                    unawaited(_loadDeviceTones());
                  },
                )
              : null,
        ),
      ]);
    }

    return _card(context, [
      for (final (index, tone) in tones.indexed)
        _tile(
          context,
          first: index == 0,
          title: tone.name,
          subtitle: AppLocalizations.of(context).toneSheetOnThisDevice,
          selected:
              settings.usesDeviceTone &&
              settings.adhanDeviceToneUri == tone.uri,
          leading: _previewButton(
            context,
            enabled: true,
            playing: _playing == _deviceKey(tone),
            onPressed: () => _toggleDevicePreview(tone),
          ),
          onTap: () =>
              _select(settings.withDeviceTone(name: tone.name, uri: tone.uri)),
        ),
    ]);
  }

  Widget _messageRow(
    BuildContext context, {
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: UiText(
                  message,
                  type: UiTextType.bodyMedium,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }

  bool _selected(AppSettings settings, AdhanTone tone) {
    return _kind == NotificationKind.adhan
        ? !settings.usesDeviceTone && settings.adhanTone == tone.name
        : settings.preAlertTone == tone.name;
  }

  Widget _card(BuildContext context, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.4),
      ambient: false,
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
          title: UiText(title, type: UiTextType.bodyLarge),
          subtitle: UiText(subtitle, type: UiTextType.bodyMedium),
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
      tooltip: enabled
          ? AppLocalizations.of(context).toneSheetPreviewTooltip
          : AppLocalizations.of(context).toneSheetPreviewUnavailableShort,
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
    return UiText(
      label,
      type: UiTextType.titleSmall,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
