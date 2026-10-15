import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/core/ui/widgets/blur_surface.dart';

/// Shows a modal over a **full-screen frosted backdrop**.
///
/// This is the difference between "a translucent card" and the way the system
/// draws a dialog: the whole screen behind the dialog goes soft, not just the
/// card. A plain [showDialog] cannot produce it, because a `Dialog` can only
/// blur *within its own bounds* — everything outside the card stays sharp.
///
/// The route deliberately applies **no opacity transition of its own**. An
/// `OpacityLayer` between the backdrop and a `BackdropFilter` makes the filter
/// composite against an empty surface, so the blur would only pop in once the
/// animation settled. Instead the blur sigma and the scrim ramp with the route
/// animation inside the page, and only the card is wrapped in a
/// [FadeTransition] — so the frost is live from the first frame.
///
/// [builder] should return a widget that supplies its own surface (a
/// [Material], or a [BlurSurface] wrapped in one) — same contract as
/// `showGeneralDialog`, since this is a route rather than a `Dialog`.
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double blurSigma = 24,
  double scrimOpacity = 0.28,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // The scrim is painted by the page below, on top of the blur; the route's
    // own barrier stays invisible so it only catches the dismiss tap.
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 240),
    // Identity: the fade lives inside the page so the BackdropFilter is never
    // wrapped in an OpacityLayer (see the note above).
    transitionBuilder: (_, _, _, child) => child,
    pageBuilder: (context, animation, _) => _BlurredDialogOverlay(
      animation: animation,
      blurSigma: blurSigma,
      scrimOpacity: scrimOpacity,
      child: builder(context),
    ),
  );
}

/// The blurred backdrop plus the centered, fading card.
class _BlurredDialogOverlay extends StatelessWidget {
  const _BlurredDialogOverlay({
    required this.animation,
    required this.blurSigma,
    required this.scrimOpacity,
    required this.child,
  });

  final Animation<double> animation;
  final double blurSigma;
  final double scrimOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Read outside the builder: this is an InheritedWidget lookup, and the
    // overlay is built once, under the app's ReduceTransparency scope.
    final reduceTransparency = BlurSurface.shouldReduceTransparency(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Ease the whole effect in by hand — the route has no transition of its
        // own to lean on.
        final t = Curves.easeOut.transform(animation.value);
        final scrim = ColoredBox(
          color: scheme.scrim.withValues(alpha: scrimOpacity * t),
        );

        return Stack(
          children: [
            // The backdrop: everything behind the route, blurred, with the scrim
            // over the top. Kept out of any opacity layer so the filter stays
            // live for the whole animation.
            Positioned.fill(
              child: reduceTransparency
                  ? scrim
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurSigma * t,
                        sigmaY: blurSigma * t,
                      ),
                      child: scrim,
                    ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.huge,
                      vertical: AppSpacing.giga,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
