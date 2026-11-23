import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The stable/beta choice, shared by Settings and the Update Center.
///
/// It lives in the ordinary settings information architecture now, but the
/// contract is unchanged: the notifier is the only writer, switching is blocked
/// while a download is in flight, and both options explain themselves so this
/// is never a hidden developer toggle. Keeping one widget means the two hosts
/// cannot drift in wording or availability.
class UpdateChannelSelector extends ConsumerWidget {
  const UpdateChannelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      ambient: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: UiText(
                  l10n.updateReleaseChannel,
                  type: UiTextType.titleSmall,
                  fontWeight: AppWeight.semibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final channel in UpdateChannel.values)
            _ChannelOption(
              channel: channel,
              label: channel == UpdateChannel.stable
                  ? l10n.updateChannelStable
                  : l10n.updateChannelBeta,
              description: channel == UpdateChannel.stable
                  ? l10n.updateChannelStableDescription
                  : l10n.updateChannelBetaDescription,
              selected: state.channel == channel,
              enabled: !state.isDownloading,
              onTap: () => notifier.setChannel(channel),
            ),
        ],
      ),
    );
  }
}

class _ChannelOption extends StatelessWidget {
  const _ChannelOption({
    required this.channel,
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final UpdateChannel channel;
  final String label;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        enabled: enabled,
        button: true,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Opacity(
            opacity: enabled ? AppOpacity.full : AppOpacity.faintMark,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.giga),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
                color: selected
                    ? scheme.primaryContainer.withValues(
                        alpha: AppOpacity.faintMark,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.jumbo,
                    height: AppSpacing.jumbo,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outline,
                        width: AppStroke.focus,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: AppSpacing.md,
                              height: AppSpacing.md,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.giga),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          label,
                          type: UiTextType.titleSmall,
                          fontWeight: AppWeight.semibold,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        UiText(
                          description,
                          type: UiTextType.bodySmall,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
