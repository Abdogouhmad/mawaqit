import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';

/// Android 17-style frosted surface: calm and tonal, deliberately *not* iOS
/// liquid glass.
///
/// There are no specular highlights, no refraction and no rainbow edges — just a
/// blurred, lightly tinted slab with a single hairline border and at most one
/// soft shadow. An earlier draft added a lit top edge on the theory that glass
/// needs something to catch; against a backdrop that already varies it read as a
/// wash across the top of the pill instead, so it is gone. The blur and the
/// hairline are the whole effect.
///
/// One detail does the actual work of making it read as glass rather than as a
/// grey slab, and it is the one the nav bar leans on: **low tint, high sigma**.
/// The fill has to stay thin or the blur behind it is invisible. At a 0.55 fill
/// with sigma 30 the backdrop genuinely shows through, smeared past recognition.
///
/// Applied to a small, deliberate set of surfaces — the floating nav bar, sheet
/// handles, scrims. Cards stay flat: blurring everything is both expensive and
/// visually noisy.
class BlurSurface extends StatelessWidget {
  const BlurSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.sigma = defaultSigma,
    this.opacity,
    this.border = true,
    this.shadows = true,
    this.padding,
    this.neutralTint = false,
    this.backdropSaturation = 1.0,
  });

  /// 24 is the sweet spot: readable through busy content, cheap enough not to
  /// drop frames. The nav bar asks for [maxSigma] instead.
  static const double defaultSigma = 24;
  static const double maxSigma = 30;

  /// Frost tint strength when a surface has not asked for something specific.
  static const double defaultOpacity = 0.72;

  /// Light mode nudges up on the default: a lighter backdrop makes the same
  /// alpha read as too transparent.
  static const double lightOpacity = 0.82;

  /// How much of a tint's chroma to strip when [neutralTint] is on.
  ///
  /// Not all the way to zero: a colour with no hue at all reads as dead grey
  /// beside this app's warm off-white canvas, which is itself very slightly
  /// warm. Keeping a small residue holds the surface in the same tonal family
  /// while removing the cast that made it look tinted.
  static const double neutralAmount = 0.82;

  final Widget child;
  final double radius;

  /// Blur strength, clamped to [maxSigma].
  final double sigma;

  /// Alpha of the tonal fill painted over the blur.
  ///
  /// `null` takes the per-brightness default above. Supplying a value overrides
  /// both — a surface that needs a *lighter* frost to actually look frosted
  /// cannot get there while light mode is pinned to [lightOpacity].
  final double? opacity;
  final bool border;
  final bool shadows;
  final EdgeInsetsGeometry? padding;

  /// Drops the fill's hue, keeping its lightness.
  ///
  /// `surfaceContainer` is nominally neutral but the palettes tint it: the dark
  /// value is measurably green (`0xFF151B18`), so a frost built on it drags the
  /// brand hue into the chrome and the bar stops reading as glass over the
  /// content and starts reading as a coloured object sitting on it. Deriving the
  /// neutral from the fill itself — rather than hardcoding a grey — keeps the
  /// result in the right tonal register for every palette and both brightnesses.
  final bool neutralTint;

  /// Saturation applied to the *blurred backdrop*, before the fill goes over it.
  ///
  /// Real frosted glass does not only blur, it concentrates: light passing
  /// through the roughened surface loses its short wavelengths less than a plain
  /// box blur would, so colours behind the bar come out slightly richer. Nudging
  /// saturation up is what separates "blurred panel" from "glass".
  ///
  /// 1.0 is off. Values far from 1.0 look like a colour filter over the UI.
  final double backdropSaturation;

  /// Whether a live blur should be skipped in favour of an opaque fill.
  ///
  /// Two independent ways to get here: the user asked for it in Settings →
  /// Appearance → "Reduce transparency", or the platform reports animations are
  /// off (battery saver), in which case a per-frame blur is exactly the wrong
  /// thing to spend frames on.
  static bool shouldReduceTransparency(BuildContext context) =>
      ReduceTransparency.of(context) ||
      MediaQuery.maybeDisableAnimationsOf(context) == true;

  /// Strips [neutralAmount] of a colour's chroma, leaving lightness untouched.
  static Color neutralize(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(hsl.saturation * (1 - neutralAmount))
        .toColor();
  }

  /// Luminance-preserving saturation matrix.
  ///
  /// Each output channel is the matching input scaled by `s` plus the luma of the
  /// other two, so `s == 1` is the identity and every channel keeps its original
  /// brightness. The coefficients sum to 1 per row, which is what stops the
  /// backdrop from brightening or darkening as the effect is dialled up.
  static List<double> _saturationMatrix(double s) => [
    0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0,
    0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0,
    0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final reduceTransparency = shouldReduceTransparency(context);

    final tintAlpha =
        opacity ??
        (brightness == Brightness.light ? lightOpacity : defaultOpacity);

    final baseTint = neutralTint ? neutralize(scheme.surfaceContainer) : scheme.surfaceContainer;

    final tint = reduceTransparency
        ? baseTint
        : baseTint.withValues(alpha: tintAlpha);

    // A finite radius token, never `double.infinity`. `ClipRRect` clamps each
    // radius to half its box's side, so [AppRadius.pill] already comes out as a
    // full stadium — whereas an infinite radius makes `RRect` scale by an
    // infinite factor and asserts inside the engine on the first hit test.
    final shape = BorderRadius.circular(radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: shape,
        border: border
            ? Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (reduceTransparency) {
      // Opaque fallback: no BackdropFilter, so nothing to repaint per frame.
      return _Shadow(
        enabled: shadows,
        radius: radius,
        child: ClipRRect(borderRadius: shape, child: surface),
      );
    }

    return _Shadow(
      enabled: shadows,
      radius: radius,
      child: RepaintBoundary(
        // BackdropFilter is expensive; isolating it keeps the rest of the
        // chrome's repaints cheap.
        child: ClipRRect(
          borderRadius: shape,
          child: BackdropFilter(
            filter: _backdropFilter(),
            child: surface,
          ),
        ),
      ),
    );
  }

  /// Blur, with the optional saturation pass folded into the same filter.
  ///
  /// Two filters in a row would cost two backdrop passes per frame, so the
  /// saturation is *composed* onto the blur instead. Order matters: in
  /// [ImageFilter.compose] the `outer` filter is applied last, and saturating
  /// after blurring is the whole point — saturating first would be undone by
  /// the blur mixing neighbouring pixels back together.
  ImageFilter _backdropFilter() {
    final s = sigma.clamp(0.0, maxSigma);
    final blur = ImageFilter.blur(sigmaX: s, sigmaY: s);
    if (backdropSaturation == 1.0) return blur;
    return ImageFilter.compose(
      outer: ColorFilter.matrix(_saturationMatrix(backdropSaturation)),
      inner: blur,
    );
  }
}

/// At most one soft shadow, applied uniformly on both sides so light and dark
/// mode read the same.
class _Shadow extends StatelessWidget {
  const _Shadow({
    required this.child,
    required this.radius,
    required this.enabled,
  });

  final Widget child;
  final double radius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            // The scheme's own `shadow` role rather than a literal black: on a
            // dark surface a pure-black drop shadow is invisible, so the alpha
            // carries the whole difference.
            color: Theme.of(context).colorScheme.shadow
                .withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Settings → Appearance → "Reduce transparency", read by every [BlurSurface].
///
/// An [InheritedWidget] rather than a provider so a frosted surface can be
/// dropped anywhere — including inside a `BottomSheet`'s own route, which is not
/// under the app's provider scope in the usual sense — and still see the setting.
class ReduceTransparency extends InheritedWidget {
  const ReduceTransparency({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReduceTransparency>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(ReduceTransparency oldWidget) =>
      oldWidget.enabled != enabled;
}
