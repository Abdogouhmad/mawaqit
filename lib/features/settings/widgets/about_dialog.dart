import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/ui/widgets/blur_surface.dart';
import 'package:mawaqit/features/settings/services/app_info.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_mark.dart';
import 'package:mawaqit/shared/ui/blurred_dialog.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Opens the app's imprint page — the mark in a mihrab niche, the wordmark, the
/// one-line promise, what the app is, and the version/privacy line.
///
/// Deliberately not the framework's `showAboutDialog`: this is the app's own
/// frosted modal, and it reads as a colophon rather than a licence dialog.
Future<void> showAboutMawaqit(BuildContext context) => showBlurredDialog<void>(
  context: context,
  builder: (_) => const _AboutCard(),
);

/// The About card itself.
///
/// Split out from the route above so the whole surface can be built — and, in
/// time, golden-tested — without pushing a route.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      // The frosted route is not a `Dialog`, so this surface — and the
      // `Material` the button needs for its ink — are ours to provide.
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: BlurSurface(
          radius: AppRadius.sheet,
          // The screen behind the card is already blurred full-screen by
          // `showBlurredDialog`; this adds the card's own frost on top — the
          // nav bar's glass recipe, with the tint left at its default rather
          // than the bar's very thin 0.5, because this surface carries a
          // paragraph of body text and readability outranks see-through.
          sigma: BlurSurface.maxSigma,
          neutralTint: true,
          backdropSaturation: 1.16,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.giga,
            AppSpacing.tera,
            AppSpacing.giga,
            AppSpacing.giga,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The one deliberate gesture: the mark framed by the app's own
              // architecture. Everything below stays quiet around it.
              const _MihrabNiche(child: AppMark()),

              const SizedBox(height: AppSpacing.xxxl),

              UiText(
                l10n.appTitle,
                type: UiTextType.titleLarge,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              UiText(
                l10n.settingsAboutTagline,
                color: scheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.giga),

              // The card's single structural device: a rule between the app's
              // identity and its specification, the way an imprint page divides
              // a colophon from its title.
              Container(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),

              const SizedBox(height: AppSpacing.giga),

              // Capped so the centred paragraph keeps a comfortable measure
              // instead of running the full width of the card.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 288),
                child: UiText(
                  l10n.updateAboutDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5),
                ),
              ),

              const SizedBox(height: AppSpacing.giga),

              UiText(
                l10n.settingsAboutVersion(AppInfo.version),
                type: UiTextType.labelMedium,
                color: scheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.huge),

              AppButton(
                label: l10n.actionClose,
                icon: Icons.close_rounded,
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app mark seated in a **mihrab niche** — a gold arch, softly lit from
/// within.
///
/// A mihrab is exactly this: the arched niche in a mosque wall that marks the
/// direction of prayer, and the shape the app's own mark already draws. It is a
/// hairline and a glow rather than a filled block, so the mark stays the only
/// solid form on the card.
class _MihrabNiche extends StatelessWidget {
  const _MihrabNiche({required this.child});

  /// Outer width. Half of it is the arch's radius, which gives the top a clean
  /// semicircle rather than an approximate curve.
  static const double _width = 112;
  static const double _height = 124;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        // The semicircle falls out of the vertical border radius; the floor
        // keeps small corners, so the shape reads as a niche and not a pill.
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_width / 2),
          bottom: Radius.circular(AppRadius.xl),
        ),
        // Light gathering in the niche, fading up into the card.
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            scheme.primary.withValues(alpha: 0.14),
            scheme.primary.withValues(alpha: 0),
          ],
        ),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.55)),
      ),
      child: Center(child: child),
    );
  }
}
