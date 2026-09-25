# Mawaqit

A calm, focused prayer-times app for Android (and Linux desktop for development) with
adhan reminders and per-prayer mute.

## Features

- **Prayer times** — precise, location-aware times via `adhan_dart` (city search,
  GPS, or manual coordinates), with a live countdown, the next-prayer progress
  row and the Hijri date alongside the Gregorian.
- **The adhan rings like a real alarm clock** — prayer calls run on Android's
  exact-alarm engine: a playback service plays the tone you chose once at alarm
  volume (the alarm stops itself when the call finishes) and the app's own
  full-screen presenter takes over the lockscreen, whether the app is open,
  closed or swiped away. Silence it with the on-screen Stop button or either
  volume key.
- **Pre-prayer alert + adhan** — two independent reminder channels with *separate*
  selectable sounds: the short pre-prayer chime and the full adhan call each have
  their own tone picker (built-in synthesised presets, custom adhans like **Adham Al
  Sharqawe**, device sounds, or Silent) and their own 3-second test button in
  Settings, so the whole chain is verifiable before a real prayer.
- **Home-screen widget** — a framed 2×2 card with the location, the next prayer, a
  countdown to the second and a five-dot day sequence (Fajr → Isha). It keeps
  advancing while the app is closed and refreshes at every prayer rollover.
- **Stitch lock-screen reminder card (Android 12+ / Pixel 9)** — an exact-alarm decorated
  card crafted to the Stitch design specification:
  - Live dynamic countdown (`Maghrib in 10 minutes`, `Maghrib in 1 minute`, `Maghrib now`).
  - Pulsing green status dot and sunset context line (`Prayer time is at 6:15 PM • Sunset at 6:14 PM`).
  - Synchronized rounded pill progress bar in Sage Emerald (`#2E7D5B` on `#B9EFD0` track) that
    tracks the active pre-prayer lead window and updates every minute.
  - Dedicated **collapsed view** (`notification_prayer_collapsed.xml`) preventing vertical clipping
    on modern Android lockscreens, and **expanded view** with **Mute this adhan** and **Dismiss**
    action pills plus an ambient sunrise/Fajr footer.
- **Per-prayer mute in-app & on card** — tap the bell icon on any prayer in-app or tap
  "Mute this adhan" directly on the lockscreen card to mute that single prayer occurrence.
- **In-app updates** — Settings checks the release manifest, shows the installed vs
  latest version with the "What's new" notes, and downloads + verifies + installs the
  new APK; a tray notification announces every release once.
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

After editing the widget schema (`lib/src/home_widget/prayer_widget.dart`), regenerate
the Glance widget and its typed Dart helper:

```sh
just widget
```

## Architecture

```
lib/
  core/        design tokens, constants, audio/catalog, time helpers
  data/
    models/        AppSettings, PrayerDay/PrayerTime
    repositories/  settings, location, prayer-times (adhan_dart)
    services/      notification_service, background_scheduler,
                   prayer_widget_service, muted_prayers_store,
                   tone_preview_service
  features/
    home/          home screen + countdown controller
    settings/      settings screen + saved-state controller
  shared/
    components/    section headers, info rows, settings groups and rows
    ui/            AppButton, AppCard, AppPill, UiText, option sheet…
  src/home_widget/  home-widget DSL schema + its generated helper
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
- `AdhanScheduler.kt` / `AdhanAlarmReceiver.kt` — arms the exact per-prayer alarm and hands it to playback.
- `AdhanPlaybackService.kt` — foreground playback of the adhan (one pass) at alarm volume.
- `MainActivity.kt` — also raises the in-app adhan presenter over the lockscreen when the alarm fires.
- `PrayerWidgetHomeWidget.kt` / `PrayerWidgetHomeWidgetReceiver.kt` — the Glance home-screen widget.

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