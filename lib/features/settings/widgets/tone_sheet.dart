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
  String? _playing;

  NotificationKind get _kind => widget.kind;

  List<AdhanTone> get _tones => _kind == NotificationKind.adhan
      ? ToneCatalog.tones
      : ToneCatalog.preAlertTones;

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
            UiText('${_kind.label} Tone', type: UiTextType.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            UiText(
              'Tap the speaker to preview a sound before choosing.',
              type: UiTextType.labelMedium,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _sectionLabel(context, 'Built-in tones'),
            const SizedBox(height: AppSpacing.sm),
            _card(context, [
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
                  selected: _selected(settings, tone),
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
                    _kind == NotificationKind.adhan
                        ? settings.withBundledTone(tone.name)
                        : settings.withPreAlertTone(tone.name),
                  ),
                ),
            ]),
          ],
        ),
      ),
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
    return UiText(
      label,
      type: UiTextType.titleSmall,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
