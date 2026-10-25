import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/features/settings/widgets/about_dialog.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';

/// The "About & update" card shown on the settings screen: a software-update
/// entry that opens the OTA center, plus the installed-version row.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Select only what this row displays: the store emits on every download
    // progress tick, and the settings list has no business rebuilding for it.
    final (hasUpdate, status) = ref.watch(
      updateProvider.select((s) => (s.hasUpdate, s.status)),
    );

    final shouldHighlight = hasUpdate && status != UpdateStatus.error;

    return SettingsGroup(
      children: [
        SettingsRow(
          icon: Icons.system_update_alt_rounded,
          title: l10n.updateSoftwareUpdate,
          subtitle: 'v${AppInfo.version}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OtaUpdateScreen()),
          ),
          trailing: shouldHighlight
              ? AppPill(
                  label: l10n.updateBadge,
                  icon: Icons.system_update_rounded,
                  dense: true,
                  color: scheme.primary,
                )
              : const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          title: l10n.updateAboutMawaqit,
          subtitle: l10n.updateAboutBody,
          onTap: () => showAboutMawaqit(context),
          trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
      ],
    );
  }
}
