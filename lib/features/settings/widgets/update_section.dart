import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';
import 'package:mawaqit/shared/widgets/settings_group.dart';
import 'package:mawaqit/shared/widgets/settings_row.dart';

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
          title: 'Software Update',
          subtitle: 'v${AppInfo.version}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OtaUpdateScreen()),
          ),
          trailing: shouldHighlight
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.system_update_rounded,
                        size: AppIconSize.sm,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Update available',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          title: 'About Mawaqit',
          subtitle: 'No accounts, no tracking — prayer times at your side',
          onTap: () => _showAbout(context),
          trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mawaqit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppInfo.version}',
              style: textTheme.bodyMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A calm, focused prayer-times app with adhan reminders. '
              'No accounts, no tracking.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
