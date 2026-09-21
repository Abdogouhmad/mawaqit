# Changelog

> **This file is the single source of truth for release notes.** The GitHub
> release workflow (`./build.sh --release-notes` → `.github/workflows/
> release.yml`) extracts the matching `## [<version>]` section and uses it
> verbatim as the release body. Every user-visible change MUST be recorded
> here — plain Keep a Changelog, one bullet per user-visible change.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-09-21

First signed, releaseable build of Waqt for Android. This is a testing
release (0.x): feedback is welcome, stability guarantees come later.

### Added

- **App icon** — a new mihrab launcher icon (Android adaptive + legacy).
- **City location search** — instead of entering GPS coordinates by hand,
  pick a city by name. The settings sheet searches live as you type
  (debounced) and suggests close-name matches ("London", "Casablanca")
  with their coordinates; the chosen city is used directly for prayer
  calculations, on-device reverse geocoding and background rescheduling.
- **Design system** — shared tokens for spacing, radii, type scale and icon
  sizes (`AppSpacing/AppRadius/AppFontSize/AppIconSize`), the Sage Emerald
  material palette, and the bundled Manrope typeface across the whole app.
- **More adhan tones + sound preview** — twelve built-in presets (Traditional
  Adhan, Mellow Bell, Minimal Chime, Desert Wind, Nabawi Melody, Zen Bow,
  Dawn Call, Amber Bell, Soft Harp, Medina Breeze, Night Calm, Tranquil Gong,
  plus Silent) with an in-app preview that lets you hear a tone before choosing
  it. The selected tone now also drives the prayer-entry alarm sound. All tones
  are original synthesised WAVs (`tool/gen_tones.py`), so nothing is bundled
  from third parties.
- **Device ringtone / notification sounds** — the tone picker also lists the
  notification, alarm and ringtone sounds already on your phone (Android), lets
  you preview them, and uses the chosen one for the prayer-entry alarm. Picking
  a built-in tone clears the device override.
- **Android release pipeline** — `build.sh` builds and **signs** three APKs
  (armeabi-v7a, arm64-v8a and a universal fat APK) with a stable keystore,
  stages `dist/`, writes `checksums.txt` and verifies every APK with
  `apksigner`; the GitHub Action publishes them as a full GitHub release.
- **Linux desktop development support** — run `just run-linux` to develop
  on the desktop (background scheduling is Android-only and safely skipped).
- **Lockscreen prayer card** — a decorated, exact-alarm reminder card with
  a live countdown, progress bar, Mute/Dismiss quick actions (Android 13+).

### Changed

- Notifications redesigned to match the Stitch reference: Waqt badge + APP
  row, pulsing "next prayer" dot, prayer-time meta line, horizon glyph,
  sage progress bar and two pill quick actions.
- Pre-prayer alert and segmented controls now animate smoothly: the selection
  highlight slides between options and the lead-time label cross-fades/scales.
- Tone preview on Linux desktop no longer depends on GStreamer plugins — it
  falls back to `paplay`/`aplay`/`ffplay`, so dev previews just work.

### Fixed

- **Tone preview crash on Linux desktop** ("Your GStreamer installation is
  missing a plug-in") — audioplayers is now only used on mobile; desktop uses a
  system CLI, and a missing backend shows a hint instead of throwing.
- **City search crash on desktop** ("Null check operator") — the platform
  geocoder has no Linux implementation; search now falls back to OpenStreetMap
  Nominatim so it works in development and on mobile.
- **Runtime circular-dependency crash** — saving a setting no longer triggers
  an invalidate-everything cascade (settings changes propagate automatically).
- **Location sheet exceptions** — background ripple/ink assertion, overflow
  with the keyboard open, and "controller used after being disposed" when
  closing the sheet mid-search are all fixed; results are safe to shut down.
- Vastly oversized `versionCode`/max-height artifacts and stale release notes
  ordering — the pipeline derives everything from `version:` in `pubspec.yaml`.

[0.2.1]: https://github.com/Abdogouhmad/mawaqit/releases/tag/v0.2.1