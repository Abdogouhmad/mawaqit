# Mawaqit

A calm, focused prayer-times app for Android (and Linux desktop for development) with
adhan reminders, per-prayer mute, and a home-screen widget.

## Features

- **Prayer times** — precise, location-aware times via `adhan_dart` (city search,
  GPS, or manual coordinates), with a live countdown and next-prayer progress bar.
- **Pre-prayer alert + adhan** — two independent reminder channels with *separate*
  selectable sounds: the short pre-prayer chime and the full adhan call each have
  their own tone picker (built-in synthesised presets, custom adhans like **Adham Al Sharqawe**,
  device sounds, or Silent).
- **Stitch lock-screen reminder card (Android 12+ / Pixel 9)** — an exact-alarm decorated
  card crafted to the Stitch design specification:
  - Live dynamic countdown (`Maghrib in 10 minutes`, `Maghrib in 1 minute`, `Maghrib now`).
  - Pulsing green status dot and sunset context line (`Prayer time is at 6:15 PM • Sunset at 6:14 PM`).
  - Synchronized rounded pill progress bar in Sage Emerald (`#2E7D5B` on `#B9EFD0` track) that
    tracks the active pre-prayer lead window and updates every minute.
  - Dedicated **collapsed view** (`notification_prayer_collapsed.xml`) preventing vertical clipping
    on modern Android lockscreens, and **expanded view** with **Mute this adhan** and **Dismiss**
    action pills plus an ambient sunrise/Fajr footer.
- **Test notification in Settings** — instantly renders the native pre-prayer notification
  card on Android to preview the live countdown, progress bar, and layout on your device.
- **Per-prayer mute in-app & on card** — tap the bell icon on any prayer in-app or tap
  "Mute this adhan" directly on the lockscreen card to mute that single prayer occurrence.
- **Home-screen widget** — responsive "Next prayer" card via Jetpack Glance + `home_widget`:
  adapts responsively across 2x1, 3x1, and 4x1 grid sizes with compact fallback layouts.
- **Islamic calendar** — Hijri date alongside the Gregorian.
- **Privacy-first** — no accounts, no tracking; all computation is on-device.

## Getting started

```sh
flutter pub get
flutter analyze     # must stay clean
flutter test        # unit/widget tests
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

Native Android (`android/app/src/main/kotlin/com/mawaqit/mawaqit/`):
- `PrayerScheduler.kt` — reminder channels, AlarmManager cards, test card dispatch, sunrise/sunset bookends.
- `PrayerReminderReceiver.kt` — renders the decorated collapsed and expanded cards + prayer-time flip card.
- `MutePrayerReceiver.kt` — persists per-occurrence mutes from the card's action into shared preferences.
- `PrayerWidget.kt` / `PrayerWidgetReceiver.kt` — responsive Glance home-screen widget.

Layout resources (`android/app/src/main/res/`):
- `layout/notification_prayer_collapsed.xml` — collapsed notification card for Android 12+ lockscreens.
- `layout/notification_prayer.xml` — expanded notification card with action pills and ambient footer.
- `drawable/notif_progress_bar.xml` — custom rounded pill progress bar matching Stitch Sage Emerald.
- `drawable/ic_sunny.xml` — ambient footer sunrise glyph.

## Release

Version tracks `version:` in `pubspec.yaml` (mirrored in `AppConstants.appVersion`;
`CHANGELOG.md` is the single source of truth for release notes). Build and sign the
APKs with the release pipeline:

```sh
./build.sh --release-notes    # extracts the matching CHANGELOG section
```