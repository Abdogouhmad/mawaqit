import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawaqit/core/ui/theme/motion.dart';
import 'package:mawaqit/features/settings/update_controller.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';

/// Global announcement for a newly discovered update.
///
/// Sits above the routed page in `MaterialApp.builder`, so it works on every
/// screen without interrupting the user with a dialog or snackbar. Tapping it
/// opens the software-update screen; dismissing hides only the current version
/// (a newer release brings it back).
class UpdateAvailableBanner extends ConsumerWidget {
  /// Creates the banner wrapper around the routed app.
  const UpdateAvailableBanner({
    required this.child,
    required this.onOpen,
    super.key,
  });

  /// Routed app content below the banner.
  final Widget child;

  /// Opens the software-update screen.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This wrapper is above every route. Watch only the fields it renders so a
    // download progress tick cannot rebuild the whole app.
    final banner = ref.watch(
      updateProvider.select(
        (s) => (
          hasUpdate: s.hasUpdate,
          version: s.manifest?.latestVersionName,
          dismissedVersion: s.dismissedVersion,
        ),
      ),
    );
    final version =
        banner.hasUpdate &&
            banner.version != null &&
            banner.version != banner.dismissedVersion
        ? banner.version
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: AppSpring.durationOf(context, fallback: AppMotion.short),
          curve: AppMotion.standard,
          child: version == null
              ? const SizedBox.shrink()
              : _Banner(
                  version: version,
                  onOpen: onOpen,
                  onDismiss: () => unawaited(
                    ref.read(updateProvider.notifier).dismissUpdateBanner(),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.version,
    required this.onOpen,
    required this.onDismiss,
  });

  final String version;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Material(
        color: scheme.tertiaryContainer,
        child: Semantics(
          container: true,
          button: true,
          label: l10n.updateBannerSemantics(version),
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.updateBannerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (text.titleSmall ?? const TextStyle())
                              .copyWith(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          l10n.updateBannerBody(version),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: (text.bodySmall ?? const TextStyle()).copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.updateDismissBanner,
                    icon: const Icon(Icons.close_rounded),
                    color: scheme.onTertiaryContainer,
                    onPressed: onDismiss,
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
