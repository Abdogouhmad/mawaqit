---
name: Sage Emerald
colors:
  surface: '#f9f9f6'
  surface-dim: '#dadad7'
  surface-bright: '#f9f9f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f4f1'
  surface-container: '#eeeeeb'
  surface-container-high: '#e8e8e5'
  surface-container-highest: '#e2e3e0'
  on-surface: '#1a1c1b'
  on-surface-variant: '#3f4943'
  inverse-surface: '#2f312f'
  inverse-on-surface: '#f1f1ee'
  outline: '#6f7a72'
  outline-variant: '#bec9c1'
  surface-tint: '#176b4b'
  primary: '#096444'
  on-primary: '#ffffff'
  primary-container: '#2e7d5b'
  on-primary-container: '#d0ffe3'
  inverse-primary: '#88d6af'
  secondary: '#366850'
  on-secondary: '#ffffff'
  secondary-container: '#b9efd0'
  on-secondary-container: '#3c6e56'
  tertiary: '#445c4e'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c7566'
  on-tertiary-container: '#dffbe7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a4f3ca'
  primary-fixed-dim: '#88d6af'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#b9efd0'
  secondary-fixed-dim: '#9dd2b5'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#1d5039'
  tertiary-fixed: '#cee9d6'
  tertiary-fixed-dim: '#b2cdbb'
  on-tertiary-fixed: '#082014'
  on-tertiary-fixed-variant: '#344c3e'
  background: '#f9f9f6'
  on-background: '#1a1c1b'
  surface-variant: '#e2e3e0'
typography:
  display-hero:
    fontFamily: Manrope
    fontSize: 4rem
    fontWeight: '300'
    lineHeight: 4.25rem
    letterSpacing: -0.04em
  display-hero-mobile:
    fontFamily: Manrope
    fontSize: 2.75rem
    fontWeight: '300'
    lineHeight: 3rem
    letterSpacing: -0.035em
  headline-lg:
    fontFamily: Manrope
    fontSize: 2rem
    fontWeight: '500'
    lineHeight: 2.5rem
    letterSpacing: -0.025em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 1.625rem
    fontWeight: '500'
    lineHeight: 2rem
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 1.25rem
    fontWeight: '600'
    lineHeight: 1.75rem
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Manrope
    fontSize: 1.125rem
    fontWeight: '400'
    lineHeight: 1.75rem
    letterSpacing: -0.01em
  body-md:
    fontFamily: Manrope
    fontSize: 0.9375rem
    fontWeight: '400'
    lineHeight: 1.5rem
    letterSpacing: 0em
  label-md:
    fontFamily: Manrope
    fontSize: 0.8125rem
    fontWeight: '600'
    lineHeight: 1.125rem
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Manrope
    fontSize: 0.6875rem
    fontWeight: '600'
    lineHeight: 0.875rem
    letterSpacing: 0.06em
  numeral-lg:
    fontFamily: Manrope
    fontSize: 2.25rem
    fontWeight: '400'
    lineHeight: 2.5rem
    letterSpacing: -0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1.25rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system delivers a meditative, utility-first companion designed around time, astronomical cycles, and quiet reflection. Inspired by the clarity of modern architectural chronometers and restrained environmental tools (such as Things 3 and Apple Weather), it treats temporal awareness with deep reverence while discarding archaic, ornamental, and skeuomorphic cliches.

The visual direction centers on **Warm Precision Minimalism**:
- **Demeanor**: Unhurried, deliberate, and whisper-quiet. The interface steps back entirely, allowing the passage of the sun and celestial schedules to take prominence.
- **Color Discipline**: Eschews saturated, declarative greens in favor of muted sage, oxidized botanical tones, and earthen neutrals.
- **Sensory Texture**: Ample breathable space, feather-light tactile boundaries, and gentle structural containers that mirror natural light transitions rather than harsh digital states.

## Colors

Color functions as an ambient indicator of state and time rather than decorative noise. 

### Palette Architecture
- **Primary (`#2E7D5B` in Light / `#3E9B76` in Dark)**: Used strictly for active prayer intervals, current chronometer tracking, and focal interactive states. It embodies aged stone moss and quiet foliage.
- **Secondary (`#4A7C63`)**: A dusty eucalyptus mid-tone for auxiliary prayer markers, completed milestones, and subtle progress fills.
- **Tertiary (`#8FA998`)**: A muted silver-sage used for quiet metadata, secondary indicators, and subdued graphic glyphs.
- **Neutral Canvas (`#FAFAF7` Base / `#121212` Obsidian Base)**: Creates an organic, glare-free background reminiscent of archival parchment in light mode and deep slate twilight in dark mode.

### Tonal Tiers
- **Light Surfaces**: Base canvas `#FAFAF7`, card surface `#FFFFFF`, secondary container `#F2F2ED`, subtle hairline border `#E7E7E0`.
- **Dark Surfaces**: Base canvas `#121212`, elevated card surface `#181918`, sunken surface `#141414`, subtle hairline border `#252725`.
- **Content Contrast**: Primary typography renders at `#191C1A` (Light) and `#EDEDEA` (Dark). De-emphasized timestamps use `#6D736F` (Light) and `#8A918C` (Dark).

## Typography

Typography relies entirely on **Manrope**, leveraging its clean geometric construction and balanced optical proportions.

- **Tabular Figures**: For all countdown clocks, prayer schedules, and geographic coordinates, always enable `font-variant-numeric: tabular-nums` to eliminate jitter across real-time updates.
- **Display Weights**: Time counts and primary headlines lean into `300` (Light) and `500` (Medium) weights to maintain tranquility; avoid heavy black weights that disrupt calmness.
- **Uppercase Labels**: Small badges, astrological stages (e.g., *ZAWAL*, *QIYAM*), and status indicators take `label-sm` with slight uppercase tracking (`0.06em`) for disciplined legibility.

## Layout & Spacing

The layout model emphasizes a single, focused column of temporal progression, preventing peripheral cognitive load.

- **Grid Architecture**:
  - **Mobile (< 768px)**: 4-column fluid structure, `1.25rem` outer canvas margin, `1rem` column gutters. Vertical stacking rules govern all prayer sequence intervals.
  - **Tablet (768px – 1024px)**: 8-column layout, `2rem` margin. The active prayer hero shares horizontal hierarchy with the companion solar arc.
  - **Desktop (> 1024px)**: Centered fixed container with max-width `720px` for utility focus, expanding to a 12-column grid (`max-width: 1140px`) strictly when displaying annual astrological almanacs or monthly prayer tables.
- **Rhythm & Negative Space**: Vertical padding inside sequence rows should never feel crowded. Maintain a minimum of `1.5rem` between distinct temporal zones (Past, Present Active, Upcoming).

## Elevation & Depth

Visual hierarchy is maintained through **Tonal Separation** and ultra-diffused atmospheric backdrops, avoiding heavy drop shadows.

- **Level 0 (Canvas)**: Baseline surface (`#FAFAF7` light / `#121212` dark).
- **Level 1 (Card & Module Containers)**: Soft fill (`#FFFFFF` light / `#181918` dark) bordered by a gentle ghost hairline: `1px solid rgba(0, 0, 0, 0.04)` in light mode, `1px solid rgba(255, 255, 255, 0.06)` in dark mode.
- **Level 2 (Active Prayer Focus)**: The ongoing prayer card elevates via a dual ambient blur: `0 8px 32px -4px rgba(46, 125, 91, 0.08)` in light mode, and a soft emerald floor glow `0 8px 32px -4px rgba(62, 155, 118, 0.12)` in dark mode.
- **Level 3 (Sheets & Pickers)**: Glassmorphic surface utilizing `backdrop-filter: blur(20px)` at 85% opacity, paired with an inner top highlight border `rgba(255, 255, 255, 0.2)` in light and `rgba(255, 255, 255, 0.08)` in dark.

## Shapes

Shapes emulate organic river stones and contemporary industrial forms.

- **Base Corner Radius**: Standard interactive controls utilize `0.5rem` (rounded).
- **Cards & Primary Modules**: Utilize `1.25rem` to `1.5rem` (`rounded-xl` / `rounded-2xl`) for a soft, tactile presence that feels welcoming on mobile touchpoints.
- **Pill Badges & Sliders**: Badges, time chips, and navigation segments use fully rounded circular capsules (`border-radius: 9999px`) to cleanly demarcate micro-status indicators from larger structural cards.

## Components

### Prayer Schedule Row & Cards
- **Inactive / Future Row**: Minimalist hairline layout, displaying prayer name (`headline-md`) on the leading edge and time (`numeral-lg` formatted with tabular numbers) trailing. Opacity sits at 65% for past prayers.
- **Active Prayer Card**: Expanded container (`rounded-2xl`) filled with faint tint (`rgba(46, 125, 91, 0.06)` light / `rgba(62, 155, 118, 0.1)` dark), bordered by a 1px primary accent ring. Displays dynamic countdown timer and visual sun elevation path.

### Buttons & Quick Actions
- **Primary Button**: Pill-shaped (`9999px`), filled with Primary Accent (`#2E7D5B` / `#3E9B76`), pure white text, zero inner stroke, slight compression animation on press (`scale: 0.98`).
- **Secondary / Ghost Button**: Pill-shaped container with subtle neutral fill (`#F2F2ED` light / `#202220` dark) and matching muted typography.
- **Icon Actions**: Circular bounding boxes (`44x44px`) with centered 20px optical vector icons (Qibla compass, audio toggle, notifications).

### Chips & Pill Badges
- **Status Indicator**: Pill shape with `0.25rem` horizontal gap between a pulsing `6px` circular dot and `label-sm` text (e.g., "NEXT IN 42M", "JUMU'AH").
- **Calculation Method Badges**: Translucent capsules with `label-sm` tracking, providing clear feedback on selected convention (e.g., "MWL 18°", "ISNA").

### Lists & Form Inputs
- **Dividers**: Non-structural; spacing and tonal shifts serve as division. Hairline separators are limited to `rgba(0, 0, 0, 0.05)` when lists require strict data density.
- **Input Fields (City / Location Search)**: Pill or `rounded-xl` search fields with soft inner fill, no default outer border, and a persistent location indicator glyph.

### Qibla & Celestial Trackers
- **Solar Arc Progress**: Hairline arc stroke (`2px`) tracing dawn to nightfall with an organic dot indicating current celestial progression.
- **Compass Disk**: Concentric rings with micro-notches, rendered with low contrast (`rgba(0,0,0,0.15)`), orienting effortlessly toward Makkah with damp spring physics.