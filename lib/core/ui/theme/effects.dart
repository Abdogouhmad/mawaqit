/// Non-colour visual tokens: opacity, stroke, elevation, blur and the few
/// component dimensions that are not spacing steps.
///
/// These exist for the same reason [AppSpacing] and [AppRadius] do: a widget
/// should say *what* the value means, not spell `0.55` or `Offset(0, 1)` again.
/// Opacity is kept separate from [AppColors] because an alpha is a decision
/// about hierarchy, not a new colour — the underlying scheme role still comes
/// from the theme.
library;

import 'package:flutter/material.dart';

import 'shapes.dart';

/// Alpha values used when a theme colour is softened.
abstract final class AppOpacity {
  const AppOpacity._();

  static const double none = 0;
  static const double full = 1;

  /// Quietest decorative wash: selected option sheets, ambient card glow.
  static const double whisper = 0.05;

  /// Tonal icon badges and section markers.
  static const double soft = 0.08;

  /// Accent pills and small tinted chips.
  static const double accent = 0.12;

  /// Soft brand wash behind the About dialog's mark.
  static const double ambient = 0.14;

  /// Error-coloured hairline around an inline error card.
  static const double errorOutline = 0.3;

  /// Leading-icon badge fill used across settings rows.
  static const double badge = 0.55;

  /// Neutral pill background when no accent is supplied.
  static const double neutralPill = 0.6;

  /// A muted caption sitting on a tonal surface.
  static const double mutedCaption = 0.7;

  /// Secondary copy that must still read as text, not as a divider.
  static const double secondaryText = 0.75;

  /// Inactive dots and long-passed rows.
  static const double faintMark = 0.5;

  /// Passed times in today's row: dimmed, but still readable.
  static const double passedTime = 0.55;

  /// Disabled picker cells and other non-interactive ink.
  static const double disabled = 0.38;

  /// Caption ink that is softer than body copy but not a divider.
  static const double supportingInk = 0.85;

  /// Translucent halo around the sun marker on the solar arc.
  static const double arcGlow = 0.18;

  /// Qibla alignment beam wash once the needle is inside the slot.
  static const double qiblaBeamAligned = 0.34;

  /// Hairlines and dividers that should read as structure, not ink.
  static const double hairline = 0.4;

  /// Selected row wash and very subtle state fills.
  static const double selectedRow = 0.06;

  /// Modal scrim over a blurred backdrop.
  static const double scrim = 0.28;

  /// Navigation bar interaction overlay.
  static const double navOverlay = 0.1;

  /// Ambient card glow: light mode stays almost invisible.
  static const double cardAmbientLight = 0.05;
  static const double cardAmbientDark = 0.12;

  /// Frosted-surface fills. Kept here so [BlurSurface] and its callers agree.
  static const double frostDefault = 0.72;
  static const double frostLight = 0.82;
  static const double frostNeutral = 0.82;

  /// Shadow alphas: a dark surface needs more alpha to read at all.
  static const double shadowLight = 0.10;
  static const double shadowDark = 0.45;

  /// Breathing pulse's halo, from [pulseGlowPeak] down to zero.
  static const double pulseGlowPeak = 0.55;
  static const double pulseGlowDrop = 0.35;
}

/// Hairline widths, focus rings and progress thicknesses.
abstract final class AppStroke {
  const AppStroke._();

  static const double hairline = 1;
  static const double focus = 2;
  static const double selected = 3;
  static const double arcTrack = 2;
  static const double spinner = 2.4;
}

/// Shadow geometry. Blur radii are spacing steps; offsets are named because a
/// top hairline and a raised card travel in different directions.
abstract final class AppElevation {
  const AppElevation._();

  static const double none = 0;
  static const double cardBlur = AppSpacing.giga;
  static const Offset cardOffset = Offset(0, AppSpacing.md);
  static const double controlBlur = AppSpacing.xs;
  static const Offset controlOffset = Offset(0, AppStroke.hairline);
  static const double frostBlur = AppSpacing.giga;
  static const Offset frostOffset = Offset(0, AppSpacing.sm);
  static const double pulseBaseBlur = AppSpacing.sm;
  static const double pulseRangeBlur = AppSpacing.sm;
  static const double pulseSpread = AppSpacing.xxs;

  /// Soft halo under the Qibla alignment arc once the needle is inside it.
  static const double qiblaArcBlur = AppSpacing.xs;
}

/// Backdrop-filter sigmas.
abstract final class AppBlur {
  const AppBlur._();

  static const double dialog = 24;
  static const double surface = 24;
  static const double surfaceMax = 30;
}

/// Component-level sizes that are meaningful only as a whole.
abstract final class AppSize {
  const AppSize._();

  static const double zero = 0;

  /// Gap between a small leading icon and its label.
  static const double iconLabelGap = AppSpacing.sm;

  /// Badge in a section header — one step below the standard 40dp control.
  static const double sectionBadge = AppSpacing.emphasis;

  /// Bare icon in a two-column detail row.
  static const double detailIcon = AppSpacing.giga;

  /// Inline activity indicator inside an action button.
  static const double buttonSpinner = AppSpacing.jumbo;

  /// Empty-state icon disc and brand-mark sizes.
  static const double emptyStateDisc = AppSpacing.block * 2;
  static const double markAbout = 72;
  static const double markFooter = 44;

  /// Maximum widths of the About dialog and its body copy.
  static const double dialogMaxWidth = 360;
  static const double aboutBodyMaxWidth = 288;

  /// Status-card and large success glyphs in the Update Center.
  static const double statusIcon = 42;
  static const double largeStatusIcon = 64;

  /// Palette choice swatch and the accent dot drawn inside it.
  static const double paletteSwatch = 46;
  static const double paletteAccent = 24;

  /// Mihrab niche around the About dialog's brand mark.
  static const double nicheWidth = 112;
  static const double nicheHeight = 124;

  /// Smallest segment that can still carry an icon beside its label.
  static const double minSegmentForIcon = 100;

  static const double pulseDot = 8;
  static const double pulseScaleBase = 0.8;

  /// Solar arc geometry: height, horizon ticks and the travelling sun marker.
  static const double solarArcHeight = 64;
  static const double arcHorizonDot = 2.5;
  static const double arcSunCore = 4.5;

  /// Height of the thin temporal-progress track in the countdown hero.
  static const double progressTrackHeight = AppSpacing.sm;
  static const double pulseScaleRange = 0.4;

  /// Bottom navigation. The icon is 24dp — the Material default and one step
  /// above [AppIconSize.xxl] — so the bar does not inherit an SDK magic number.
  static const double navigationBarHeight = AppSpacing.offsetLg;
  static const double navigationIcon = AppSpacing.giga;
  static const double navigationLabelPadding = AppSpacing.xs;

  /// Qibla dial. Capped so it stays a quiet instrument on tablets instead of
  /// growing into a full-screen target.
  static const double qiblaDialMax = AppSpacing.progress;

  /// Needle geometry, as fractions of the dial radius.
  static const double qiblaNeedleTip = 0.74;
  static const double qiblaNeedleTail = 0.20;
  static const double qiblaNeedleHalfWidth = 0.030;
  static const double qiblaNeedleWaist = 0.30;

  /// Where the gold half of the needle hands over to the emerald tail, as a
  /// fraction of the needle's own bounding box (tip at 0, tail at 1).
  static const double qiblaNeedleGoldStop = 0.78;

  /// Counterweight disc at the tail, relative to the needle half-width.
  static const double qiblaTailDot = 0.85;

  /// Kaaba marker. The cube scales with the dial; the legend uses a fixed size.
  static const double qiblaCubeScale = 0.10;
  static const double qiblaCubeRadius = 0.2;
  static const double qiblaCubeBand = 0.26;
  static const double qiblaCubeBandTop = 0.14;
  static const double qiblaCubeGlowOuter = 0.90;
  static const double qiblaCubeGlowInner = 0.62;

  /// The gold beam the needle must enter, and the inner ring it sits against.
  static const double qiblaBeamInner = 0.62;
  static const double qiblaInnerRing = 0.80;

  /// Tick lengths, the beam's inset and the rule between the two readouts.
  static const double qiblaTickMajor = AppSpacing.md;
  static const double qiblaTickMinor = AppSpacing.xs;
  static const double qiblaArcInset = AppSpacing.xxs;
  static const double qiblaReadoutRule = AppSpacing.tera;

  /// Hub that covers the needle's pivot.
  static const double qiblaHub = AppSpacing.giga;
  static const double qiblaHubDot = AppSpacing.xs;
}

/// Shape constants shared by more than one primitive.
abstract final class AppShape {
  const AppShape._();

  /// The selected navigation indicator and other pill-shaped controls.
  static const ShapeBorder pill = StadiumBorder();
}

/// Font weights used by components, so a widget does not mix its own steps with
/// the type scale's.
abstract final class AppWeight {
  const AppWeight._();

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// Breakpoints and proportional constraints.
abstract final class AppLayout {
  const AppLayout._();

  /// Phone-first content stops stretching here on tablets and foldables.
  static const double maxContentWidth = 600;

  /// A bottom sheet never covers more of the screen than this.
  static const double sheetMaxHeightFactor = 0.7;

  /// Above this text scale, inline readouts switch to stacked ones so each
  /// figure keeps its semantic size instead of being shrunk by `FittedBox`.
  static const double largeTextScaleThreshold = 1.3;
}

/// Typographic details that belong to the token set rather than to a widget.
abstract final class AppTypeDetail {
  const AppTypeDetail._();

  static const double compactLineHeight = 1;
  static const double bodyLineHeight = 1.5;
  static const double untacked = 0;
  static const double labelTracking = 0.2;
  static const double fineTracking = 0.1;
  static const double actionLetterSpacing = 0.4;
  static const double sectionLetterSpacing = 1.4;
  static const double titleLetterSpacing = -0.2;

  /// Uppercase eyebrows and small captions.
  static const double overlineTracking = 1.2;

  /// App name in the Home header.
  static const double appTitleTracking = -0.4;

  /// The hero countdown: tight enough that a long duration still fits at 2x.
  static const double heroTracking = -1.4;

  /// Single-line meta rows at the foot of the Home screen.
  static const double footerTracking = 0.8;
}
