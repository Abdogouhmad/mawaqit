import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/ui/widgets/blur_surface.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/features/settings/widgets/ota_update_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_mark.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
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
    showDialog<void>(
      context: context,
      // Deliberately lighter than the default `Colors.black54`: the frosted
      // panel below blurs whatever is behind it, and a heavy scrim would leave
      // it blurring a flat dark wash instead of the screen.
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.28),
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        final l10n = AppLocalizations.of(dialogContext);

        return Dialog(
          // The frost *is* the dialog: a default Material fill would sit on top
          // of the BlurSurface and hide the blur behind it.
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.huge,
            vertical: AppSpacing.giga,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: BlurSurface(
              radius: AppRadius.sheet,
              // The nav bar's glass recipe: a heavier blur, a neutral fill and
              // a slightly richer backdrop. The tint is left at its default
              // rather than the bar's very thin 0.5, because this surface carries
              // a paragraph of body text and readability outranks maximum
              // see-through.
              sigma: BlurSurface.maxSigma,
              neutralTint: true,
              backdropSaturation: 1.16,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.giga,
                AppSpacing.mega,
                AppSpacing.giga,
                AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The real launcher art, above the name on the same centre axis.
                  // No backing disc: the PNG is already an emerald rounded square.
                  const AppMark(),
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
                  const SizedBox(height: AppSpacing.xxs),

                  // Close sits at the trailing edge, where a Material dialog
                  // would have put its action — but on a direction-aware
                  // alignment, so it flips to the left in Arabic.
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: UiText(
                        l10n.actionClose,
                        type: UiTextType.labelLarge,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
