import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final state = ref.watch(updateProvider);

    final shouldHighlight =
        state.hasUpdate && state.status != UpdateStatus.error;

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
          onTap: () => _showAbout(context),
          trailing: const Icon(Icons.chevron_right, size: AppIconSize.xl),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // No `title:` on purpose. AlertDialog start-aligns its title, which
        // fought the centred stack below and left the app name hanging off to
        // one side of the icon. The name is the first line of the content
        // instead, so icon, name and copy share a single centre axis.
        title: null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The mark, above the name, on the same centre axis.
            //
            // A tinted disc rather than a bare glyph, matching EmptyState: this
            // is the only ink on a near-empty canvas, and an unbacked icon at
            // that size reads as a rendering artefact rather than a logo.
            Container(
              width: AppSpacing.touch * 1.5,
              height: AppSpacing.touch * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Icon(
                Icons.mosque_rounded,
                size: AppIconSize.display,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.jumbo),

            // The app name, then the one-line promise it makes.
            UiText(
              l10n.appTitle,
              type: UiTextType.titleLarge,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            UiText(
              l10n.settingsAboutTagline,
              type: UiTextType.bodyMedium,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.giga),

            // What the app actually is. `textAlign` is not optional here:
            // UiText passes it straight through and Flutter's default is
            // `TextAlign.start`, so without it this paragraph would wrap
            // left-aligned inside a centred column and look broken.
            UiText(
              l10n.updateAboutDescription,
              type: UiTextType.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Version and privacy line, as a quiet tonal chip so the dialog has
            // a visual floor rather than trailing off into the buttons.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: UiText(
                l10n.settingsAboutVersion(AppInfo.version),
                type: UiTextType.labelMedium,
                color: scheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
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
