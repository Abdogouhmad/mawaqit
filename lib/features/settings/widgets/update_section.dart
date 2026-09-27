import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The "About & update" card shown on the settings screen: a software-update
/// entry that opens the OTA center, plus the installed-version row.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final scheme = Theme.of(context).colorScheme;

    final shouldHighlight =
        state.hasUpdate && state.status != UpdateStatus.error;

    return SettingsGroup(
      children: [
        SettingsRow(
          icon: Icons.system_update_alt_rounded,
          title: AppLocalizations.of(context).updateSoftwareUpdate,
          subtitle: 'v${AppInfo.version}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OtaUpdateScreen()),
          ),
          trailing: shouldHighlight
              ? AppPill(
                  label: AppLocalizations.of(context).updateBadge,
                  icon: Icons.system_update_rounded,
                  dense: true,
                  color: scheme.primary,
                )
              : const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          title: AppLocalizations.of(context).updateAboutMawaqit,
          subtitle: AppLocalizations.of(context).updateAboutBody,
          onTap: () => _showAbout(context),
          trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: UiText(
          AppLocalizations.of(context).appTitle,
          type: UiTextType.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiText(
              AppLocalizations.of(context)
                  .settingsAboutVersion(AppInfo.version),
              type: UiTextType.bodyMedium,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            UiText(
              AppLocalizations.of(context).updateAboutDescription,
              type: UiTextType.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: UiText(
              AppLocalizations.of(context).actionClose,
              type: UiTextType.labelLarge,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
