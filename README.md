# Mawaqit

A calm, focused prayer-times app for Android (and Linux desktop for development) with
adhan reminders, per-prayer mute, and a home-screen widget.

## Features

- **Prayer times** — precise, location-aware times via `adhan_dart` (city search,
  GPS, or manual coordinates), with a live countdown and next-prayer progress bar.
- **Pre-prayer alert + adhan** — two independent reminder channels with *separate*
  selectable sounds: the short pre-prayer chime and the full adhan call each have
  their own tone picker (built-in presets, device sounds, or Silent).
- **Lock-screen reminder card** — an exact-alarm decorated card with a live
  countdown, progress bar, and **Mute / Dismiss** quick actions (Android 13+).
  Muting affects a single prayer *occurrence* (e.g. only today's Maghrib).
- **Per-prayer mute in-app** — tap the bell icon on any prayer to mute/unmute its
  adhan for that day; muted occurrences still appear but stay silent.
- **Home-screen widget** — a compact 2x1 (resizable) "Next prayer" card via Jetpack
  Glance + `home_widget`, refreshed on launch, on each prayer rollover, and nightly.
- **Islamic calendar** — Hijri date alongside the Gregorian.
- **Privacy-first** — no accounts, no tracking; all computation is on-device.

## Getting started

```sh
flutter pub get
flutter analyze     # must stay clean
flutter test        # 21 unit/widget tests
```

Develop on the desktop (notifications work via a native Linux timer):

```sh
just run-linux
```

## Architecture

```
lib/
  core/        design tokens, constants, audio/catalog, time helpers
  data/
    models/        AppSettings, PrayerDay/PrayerTime
    repositories/  settings, location, prayer-times (adhan_dart)
    services/      notification_service, background_scheduler,
                   widget_service, muted_prayers_store, tone_preview_service
  features/
    home/          home screen + countdown controller
    settings/      settings screen + saved-state controller
  providers/       Riverpod providers wiring it together
  app.dart
```

Scheduling is platform-agnostic: the same math runs on Android (exact alarms +
native decorated card) and Linux desktop (timer-based), so the pipeline is testable
without a device.

Native side (`android/app/src/main/kotlin/com/mawaqit/mawaqit/`):
- `PrayerScheduler.kt` — reminder channels, AlarmManager cards, sunrise/fajr bookends.
- `PrayerReminderReceiver.kt` — renders the decorated card + prayer-time flip card.
- `MutePrayerReceiver.kt` — persists per-occurrence mutes from the card's action.
- `PrayerWidget.kt` / `PrayerWidgetReceiver.kt` — Glance home-screen widget.

## Release

Version tracks `version:` in `pubspec.yaml` (mirrored in `AppConstants.appVersion`;
`CHANGELOG.md` is the single source of truth for release notes). Build and sign the
APKs with the release pipeline:

```sh
./build.sh --release-notes    # extracts the matching CHANGELOG section
```