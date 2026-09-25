# Changelog

> **This file is the single source of truth for release notes.** The GitHub
> release workflow (`./build.sh --release-notes` → `.github/workflows/
> release.yml`) extracts the matching `## [<version>]` section and uses it
> verbatim as the release body. Every user-visible change MUST be recorded
> here — plain Keep a Changelog, one bullet per user-visible change.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.4] - 2026-09-25

New since v0.8.3.

### Added

- **A location-missing marker in the home header** — when prayer times can't be
  resolved (no city or GPS chosen yet, or the lookup failed), a red "location
  off" icon with a tooltip sits beside the Mawaqit title; tap it to jump
  straight to Settings and pick a place.

### Changed

- **The adhan screen now follows your theme** — the presenter dropped its fixed
  dark backdrop for the app's own surface (so it reads light in light mode),
  leads with an "IT IS TIME FOR" eyebrow over the prayer name, puts the live
  clock in a rounded card, compacts itself on short screens, pins the Stop
  button at the bottom and dismisses a beat sooner.
- **Action buttons are soft rectangles, not pills** — every primary action
  (Save location, Update now, Install now, Check for updates) uses a 14dp
  rounded shape instead of a full pill, and the adhan Stop button was tightened
  to match.
- **The home-screen widget wears a mosque mark** — a mosque icon now leads the
  MAWAQIT wordmark, the five prayer markers are drawn as true round glyphs
  (slightly larger while that prayer is active) instead of small squares, and
  the location label is a touch heavier.
- **The Settings footer uses a real clock icon** — the "◷" text glyph is now a
  Material icon, so the footer renders the same on every device.

### Fixed

- **The OTA retry button matches the update screen** — retrying a failed update
  now uses the app's own button style instead of default Material text styling.

### Removed

- **The "In …" pill on the active prayer row** — the schedule tile no longer
  repeats the countdown the hero card already shows; the live countdown stays on
  the next-prayer hero.
- **The location-off glyph on the prayer-times error card** — that indicator
  moved up into the header, so the error card keeps just its message and retry
  hint.

## [0.8.3] - 2026-09-24

New since v0.8.2.

### Added

- **A day-progress row on the home-screen widget** — five dots (Fajr → Isha)
  under the next-prayer hero mark which prayers are done, which is playing and
  what's still to come, so the whole day reads at a glance.

### Changed

- **The home-screen widget is now a framed card** — a soft rounded border and
  a theme-aware canvas (light and dark) replace the flat tile, the next-prayer
  hero (name, big countdown, clock time) sits up top, and the new dot row
  finishes the card. Colors come from the shared app palette.
- **The lockscreen alarm got a visual refresh** — a dark gradient backdrop, an
  "ADHAN" eyebrow above the prayer name, the full date line under the live
  clock, and a clearer hint: "Tap Stop or press either volume key to silence
  the call". The in-app adhan overlay was restyled to match it.
- **Every screen now uses one shared UI kit** — buttons, pills, text styles,
  icon badges, option sheets, info rows and cards were pulled into small shared
  widgets (with the palette centralized in the theme), so Home, Settings and
  the Update screen render with the same consistent shapes, spacing and fonts
  in both light and dark mode.
- **"Test Adhan" is always armed as a real alarm** — even without exact-alarm
  access the test now schedules through the native engine (degrading to an
  still-firing allow-while-idle alarm) instead of only ringing while the app
  stays open; the in-app timer is now just a last resort when no native channel
  exists.

### Fixed

- **The adhan can no longer fire with missing data after a swipe-away** — the
  schedule snapshot is embedded directly in the alarm intent (and written
  synchronously), so the receiver still has everything it needs even if the
  process was killed before the async prefs write landed.
- **Full-screen-intent denials are now visible** — on Android 14+ the app logs
  when `USE_FULL_SCREEN_INTENT` is denied, so a degraded heads-up (instead of a
  lockscreen takeover) is no longer silent.
- **Recompute cancellation is concurrent** — the stale-notification sweep now
  cancels yesterday/today/tomorrow in parallel, removing the ordering
  dependency and speeding up every reschedule.

## [0.8.2] - 2026-09-24

New since v0.7.0.

### Changed

- **A simpler home-screen widget** — the prayer card now shows just what
  matters: the location, the next prayer with a big easy-to-read time, and the
  countdown on a solid green pill. No progress bar, no clutter.
- **Alarm sounds now ship with the app** — the adhan and chime audio the alarm
  needs is included in the install. Unused bundled libraries and a leftover
  sound file were removed, and release builds now strip unused code and
  resources to keep the download as lean as possible.

### Fixed

- **The "Test Adhan" button always rings the real alarm** — full-screen like a
  prayer-time alarm, even when the adhan sound is off (then silently), even
  with the phone locked, even tapped twice in a row, and without depending on
  exact-alarm permission.
- **The adhan takes over a locked screen** — the lockscreen path now goes
  through a system alarm notification, so the call wakes the display and shows
  over the lockscreen whether the app is open, closed, or swiped away.
- **Stopping the adhan mid-load no longer crashes** — and a leftover unused
  test-reminder call was removed from the Android side.

## [0.7.0] - 2026-09-23

### Added

- **An on-device alarm clock for the adhan** — prayer-time calls now run on a
  native Android alarm engine instead of inside the app: an exact system alarm
  wakes a dedicated playback service that loops the tone you chose at alarm
  volume, and a full-screen alarm screen wakes the display and takes over the
  lockscreen. The adhan now rings even if Mawaqit was swiped away or
  force-stopped — exactly like a built-in alarm clock.
- **A refreshed Settings screen** — a friendlier header and a description under
  each section ("Where prayer times are computed for", "Rings the adhan and
  pre-prayer countdowns"…). Rows and cards are grouped and cleanly separated, so
  Location, Calculation, Notifications, Appearance and About are quicker to scan.
  Everything is still where you left it — it just reads better.

### Changed

- **Home-screen widget, compact and cleaner** — the 2×2 prayer card is now a
  tidy snapshot: the next prayer with its clock time, a live countdown, and
  the day-progress bar in the app's sage look. The old five-prayer timeline and
  the "following prayer" row were dropped to give the progress bar room to read
  at a glance.
- **The real pre-prayer reminder rings like the test** — when the app is open
  at reminder time, the countdown now plays the chime you selected directly
  instead of depending on the system notification sound, and its scheduled card
  is cancelled so nothing rings twice. With the app closed, the scheduled
  per-tone card still rings on its own.
- **Clearer notification messages** — the pre-prayer and adhan tray cards tell
  you at a glance which prayer is coming and when, and what tone will play.

### Fixed

- **The adhan can never double-ring** — when the prayer moment arrives while
  the app is open, the in-app hand-off and the timed system alarm share a single
  audio owner: whichever fires first, only one call plays (previously the two
  firing together could start the clip twice).
- **Test Adhan broke on Android 15+ and lock-screened phones** — the audible
  test is now armed through the exact-alarm engine (same path as a real prayer)
  instead of firing straight from the app, so it rings and takes over the
  full screen even when the phone is locked. The playback service also runs an
  active media session, without which Android 15+ refuses the alarm foreground
  service and kills the whole call, and the alarm card can vibrate again.
- **Test Adhan now takes over a locked screen** — pressing "Test Adhan" and
  locking your phone wakes the alarm presenter over the lockscreen like a
  native alarm, instead of just reopening the app.
- **Test Pre-Prayer rings reliably** — the 3-second test plays the chosen chime
  through the app directly, even on phones where notification-channel sounds
  get stuck.

## [0.6.0] - 2026-09-23

### Added

- **Two new adhan recitations** — **Hamza Al Majale** and **Mansur Al Zahrane**
  join the Adhan Tone picker next to Adham Al Sharqawe, so you can choose which
  voice makes the call.

### Changed

- **Every alert now has its own clear Settings section** — the notification
  area is split into two tidy cards, one for **Pre-Prayer** and one for
  **Adhan**. Each has the same simple controls, so whichever one you're looking
  at, you already know the layout: a switch to turn it on or off, a tone
  picker, and a 3-second test button.
- **The Adhan Test button now shows the real alarm, not a card** — pressing it
  fires the actual prayer-time experience: the chosen adhan rings through the
  app itself (looping like an alarm, not a one-shot note) and a full-screen,
  dark presenter takes over with the live clock. You can silence it with the
  **Stop alarm** button on screen or with the phone's **volume buttons**, just
  like a native alarm clock.
- **Pre-Prayer got its own tone and test** — the countdown reminder rings with
  the chime you pick for it, and its test button fires that exact reminder after
  3 seconds, independent of the adhan settings.
- **Each toggle and tone is remembered separately** — turning off the adhan no
  longer touches the pre-prayer reminder, and each side keeps its own chosen
  sound.

### Fixed

- **The real adhan now rings when the app is open** — previously the actual
  prayer-time call could fall silent or never take over the screen if the app
  was already on screen, because that path relied on the system notification
  sound. The app now detects the prayer moment itself and plays the chosen
  adhan directly, same as the reliable test button, with the full-screen
  presenter over whatever you were looking at.
- **A ringing adhan can always be stopped** — on-screen button and volume
  buttons both work, so the alarm can't get stuck ringing.

## [0.5.0] - 2026-09-22

### Added

- **Home-screen widget, rebuilt from scratch** — the next-prayer card returns as
  a native Android widget (Glance via `home_widget`): a "Next prayer" highlight
  with its clock time, an in-widget "in 1h 24m 13s" countdown, and all five
  prayer times (Fajr → Isha) in the app's sage look. It refreshes on app
  launch, at every prayer rollover, on settings changes and whenever the
  background reschedule runs, and tapping the card opens the app.

## [0.4.6] - 2026-09-22

### Changed

- **Live seconds in the next-prayer countdown** — the focal "NEXT PRAYER in
  2h 24m 13s" hero and the active prayer tile now count down to the second
  (the home clock already ticks every second), so the approach to each prayer
  is precise instead of rounding to the minute.

## [0.4.5] - 2026-09-22

### Fixed

- **The adhan now rings directly, Rakiz-style** — the "Test Notification" alarm
  no longer depends on the notification channel's sound being routable. The
  selected adhan tone (Settings → Adhan Tone) plays **directly through the app**
  on the Android alarm stream: it rings at the alarm volume regardless of how
  the channel sound was configured, and a disabled adhan sound stays silent.
- **Full-screen adhan presenter** — while the app is open the adhan now takes
  over the whole screen with a dedicated presenter (dark display, live clock,
  "Adhan — prayer time", and a **Stop alarm** button) instead of only a tray
  toast, so the call feels like a real alarm rather than a notification. The
  mirroring tray notification still carries vibration and the full-screen intent
  for the locked-sleeping case — now on its own silent channel, so nothing
  double-rings on top of the direct playback.

## [0.4.4] - 2026-09-22

### Added

- **New-release alerts, pushed to the tray** — on every launch (and on the
  update screen) the app now checks the OTA manifest in the background. When a
  newer version exists it posts a "Mawaqit vX.Y.Z is available" notification
  once per release, so you find out about an update without opening the app.
  The notification body previews the first highlight from the release notes.

### Fixed

- **Test Notification reliably fires the real adhan alarm** — the settings test
  no longer goes through the Doze-throttled alarm pipeline that silently
  swallowed it. It posts the full-screen adhan directly from the app 3 seconds
  after tapping: enough time to lock the screen and watch it wake, with the
  selected tone, vibration and full-screen intent on its own channel. Tapping
  the test re-asks notifications, exact-alarm and (Android 14+) full-screen
  access, so a first-launch denial no longer leaves the test dead.
- **Full-screen alarm on Android 14+** — "Notification Permission" in Settings
  now also requests full-screen-notification access, without which Android 14+
  silently caps whole-screen alerts and the adhan couldn't take over the
  lockscreen while the device sleeps.

### Removed

- **Home-screen widget** — the next-prayer card was removed from the app and is
  being rebuilt separately; prayer reminders are unaffected.

## [0.4.3] - 2026-09-22

### Added

- **Pre-prayer tone picker** — Settings now has its own "Pre-Prayer Tone" row
  alongside the Adhan Tone: twelve short chime tones (Amber Bell, Night Calm,
  Soft Harp, Mellow Bell, Minimal Chime, Tranquil Gong, Dawn Call, Zen Bow,
  Desert Wind, Traditional Adhan, Nabawi Melody, Medina Breeze) or Silent, fully
  independent from the adhan tone. The chime rings on its own channel, so the
  countdown before a prayer is instantly distinguishable from the call itself.
- **Widget survives with the app closed** — the home-screen widget was rebuilt
  as a native Android widget (plain RemoteViews, no Glance). It stores absolute
  timestamps: it advances to the next prayer on its own, counts down in real
  time, rolls past midnight into the next day's Fajr, and refreshes itself in
  the background even while Flutter is killed. Tapping the card opens the app.

### Changed

- **Instant launch from last location** — on startup the app no longer waits
  for a fresh GPS fix. It renders the prayer times immediately from the last
  cached location and refreshes in the background when the fix arrives, so the
  home screen is always populated right away and location-method or settings
  changes swap in the recomputed day without a visible reload.

### Fixed

- **"Test notification failed: invalid_sound" on Android** — bundled adhan and
  pre-prayer sounds are now attached with explicit `android.resource://` URIs
  instead of raw-resource names, which the notification plugin silently
  rejected. The selected adhan tone now plays reliably, including as the
  full-screen alarm that wakes the display over the lockscreen.
- To keep the adhan priority intact, a missing sound resource now degrades to a
  silent alert instead of aborting the whole notification.
- Notification sounds on Linux desktop load from the correct asset path
  (`audio/…` was doubled).

## [0.4.2] - 2026-09-21

### Changed

- **Test Notification now plays the actual adhan alarm** — instead of a silent
  countdown card, the Settings test trigger fires the *real* prayer-entry alert
  3 seconds out: the selected adhan tone ringing on its own channel with alarm
  audio, vibration, `Priority.max`, `CATEGORY_ALARM` and the full-screen intent
  that wakes the display over the lockscreen. The exact pipeline a scheduled
  adhan uses, so you can verify the whole chain before a real prayer.
- **Adhan vibration** — prayer-entry alerts (test and scheduled) now vibrate,
  matching alarm behavior; a muted adhan stays fully silent.

### Fixed

- **Home-screen widget never blank again** — the widget now shows a static
  sage "Mawaqit · Loading prayer times…" card the instant it is added (its own
  `initialLayout` instead of Glance's bare loading spinner), and the app seeds
  the widget bridge with a placeholder snapshot on every launch so a fresh card
  is instantly populated. A blank view after updating still needs the widget
  removed and re-added from the home screen (launcher metadata caches), but the
  content itself renders everywhere.

## [0.4.1] - 2026-09-21

### Added

- **Adhan plays while the screen is locked** — `USE_FULL_SCREEN_INTENT` and the
  full-screen intent on the prayer-entry alert wake the display over the
  lockscreen (complementing the exact-alarm / wake-lock permissions already
  present), so the adhan actually sounds when the device is off or locked.

### Changed

- **Pre-prayer alert rings again (as before)** — the countdown card is audible
  once more using the selected pre-prayer tone's own channel instead of being
  a silent card by design; selecting "Silent" still silences it.
- **Test notification fires in 3 seconds** (was 10 s, which was dropped on
  several launchers) — the Settings test trigger and its fallback timer now
  post the pre-prayer alert after 3 s.

### Fixed

- Home-screen widget "Can't show content" hardened further — `SizeMode.Single`
  renders once at the widget's own metadata size, avoiding the Glance
  responsive-size re-composition path that produced the error card on some
  launchers. If a blank view remains after updating, remove and re-add the
  widget from the home screen.

## [0.4.0] - 2026-09-21

### Added

- **In-app OTA updates** — a "Software Update" section in Settings checks a
  committed `update_manifest.json`, compares the installed build, and can
  download + install the new release directly (universal APK from GitHub
  Releases, SHA-256 verified before install). The release CI rewrites the
  manifest after every publish.
- **About Mawaqit** — an About dialog and a dedicated update screen showing
  current/latest version, last-check status and the "What's new" changelog.

### Changed

- **Only the adhan rings now** — the pre-prayer reminder card no longer plays
  a chime; it's a silent countdown card by design. The adhan ("Adham Al
  Sharqawe") is the app's single audible alert, and the tone picker lists just
  the adhan recordings (more can be added later) plus "Silent".
- **SemVer-derived versionCode** — Android `versionCode` is now computed as
  `major*10000 + minor*100 + patch` from `pubspec.yaml`, matching the OTA
  manifest and release tags exactly.

### Fixed

- **Home-screen widget "Can't show content"** — widget composition is hardened
  (all preference reads are guarded, NaN progress is clamped, errors are logged
  to logcat under "PrayerWidget"), and the widget metadata no longer tries the
  problematic narrow size bucket.

## [0.3.2] - 2026-09-21

### Added

- **Stitch pre-prayer notification card for Android & Pixel 9** —
  - Added dedicated collapsed layout (`notification_prayer_collapsed.xml`) to prevent vertical clipping on modern Android lockscreens (API 31+ / Android 14/15 on Pixel 9).
  - Designed custom rounded pill progress bar (`notif_progress_bar.xml`) in sage emerald (`#2E7D5B`) with soft sage track (`#B9EFD0`), matching the Stitch design.
  - Added sun icon (`ic_sunny.xml`) for the ambient footer row with sunrise/fajr times.
  - Subtitle dynamically displays sunset time for Maghrib (`Prayer time is at 6:15 PM • Sunset at 6:14 PM`).
  - Formatted countdown titles ("Maghrib in 10 minutes", "Maghrib in 1 minute", "Maghrib now").
- **Linked test notification to native pre-prayer card** — Tapping "Test Notification" in Settings now triggers the actual decorated Stitch pre-prayer reminder card on Android immediately, displaying the live countdown, synchronized progress bar, quick actions (Mute / Dismiss), and ambient footer.

## [0.3.1] - 2026-09-21

### Added

- **Adham Al Sharqawe adhan** — a new full-call MP3 adhan by Adham Al Sharqawe
  is now available in the Adhan Tone picker alongside the existing built-in
  tones. Previewing it works on Linux (`ffplay`) and Android (`audioplayers`).

### Fixed

- **Test notification crash on Android** — `_testNotificationId` was
  `9_000_000_001`, exceeding the signed 32-bit integer range enforced by
  Android's `validateId`. Changed to `1_999_999`, which is below the
  `nativeCard` bucket start (2,000,000) and well within the 32-bit limit.
- **Test notification button reported "unavailable"** — `scheduleTestNotification`
  was gated on `hasNotificationPermission`, silently returning `false` when
  Android permissions weren't yet granted. The guard is removed; the method now
  always attempts to post and rethrows any real error so the UI can display it
  in a SnackBar instead of showing nothing.
- **Widget renders blank at 3×1** — `PrayerWidgetContent` always rendered all
  content (name + subtitle + progress bar) regardless of widget width. Overflowing
  Glance text is fully clipped by some launchers rather than truncated. The
  composable now reads `LocalSize.current` inside `provideContent` and switches
  to a compact layout (name only, larger font) when `width < 150 dp`, preventing
  the blank 3×1 card. **Removing and re-adding the widget from the home screen
  is required** to pick up the new size metadata.
- **MP3 adhan tones silent on Linux** — `_extractAsset` always wrote the temp
  file with a `.wav` extension regardless of the actual format. MP3 content
  saved as `.wav` fails with `paplay`/`aplay` (WAV-only decoders) and is
  misparsed by `ffplay`. The temp filename now preserves the original extension
  (`.mp3` / `.wav`), and MP3 tones are routed to `ffplay` only since
  `paplay`/`aplay` cannot decode MP3.

## [0.3.0] - 2026-09-21

Reliable, testable notifications and the first home-screen widget.

### Added

- **Home-screen widget** — a compact 2x1 (resizable) "Next prayer" card built
  with Jetpack Glance and pushed from Flutter via `home_widget`: prayer name,
  clock time, "in Nm" countdown and a sage progress bar. It refreshes on app
  launch, on each prayer rollover (5x/day) and on the nightly recompute —
  no live timer inside the widget (static snapshot per push), matching the
  app's sage-green visual language.
- **Pre-prayer sound picker** — the pre-prayer alert now has its own
  selectable notification sound, fully independent from the adhan tone:
  choose any of the built-in chimes or Silent from Settings. (Adhan keeps the
  full-call tone picker.) Each selection maps to its own Android channel so
  previously-created channels never clobber the new sound.
- **Mute from the notification** — the lock-screen card's mute quick action
  actually mutes one prayer *occurrence* (e.g. only today's Maghrib.
  `PrayerScheduler` → `MutePrayerReceiver`): it persists the mute to the
  shared prefs and re-posts the notification silently. Muted occurrences still
  show (product default) but play no sound.
- **Mute/unmute from the app** — the home screen shows a small bell icon per
  prayer: tap to toggle that day's adhan on/off, with haptic feedback, a
  muted pill, and tooltips.
- **Android notification permissions** — `POST_NOTIFICATIONS` and exact-alarm
  access are requested at runtime *before* the first schedule and actually
  honored: scheduling stops cleanly when denied, and Settings gains a
  "Notification Permission" row to re-ask after a first-launch denial (no
  reinstall needed).
- **Debug test notification** — Settings has a "Test Notification" row that
  fires a pre-prayer alert 10 seconds out, so the whole notify pipeline is
  verifiable on Linux desktop before packaging an APK.

### Changed

- Notifications are now fully cross-platform testable: the scheduling math is
  platform-agnostic and runs identically on Android and Linux desktop
  (Linux posts reminders via a temporary timer — same pipeline, no waiting
  for prayer times).
- Two distinct sound channels (`pre_prayer_alert_v2` for the short chime,
  `prayer_adhan_v2` for the full call) are now selected by notification type
  instead of reusing one channel for both.
- The pre-prayer card is posted at **alert time** (lead minutes before the
  prayer), not at adhan time, and its progress bar reflects the elapsed
  fraction between "alert posted" and "prayer time".
- When exact alarms aren't granted (Android 12/13 devices), reminders degrade
  to inexact scheduling instead of silently doing nothing.
- Scheduled times are built with `tz.TZDateTime` under the device timezone and
  fire with `AndroidScheduleMode.exactAllowWhileIdle`; reminder ids are
  deterministic per day so reschedules can never double-fire or drop silent.

### Fixed

- Pre-prayer and adhan notifications could fire at the wrong time (naive
  `DateTime`, `inexact` mode, offset added instead of subtracted, or applied
  twice on reschedule).
- Stale notifications for an already-passed day could double-fire after the
  nightly recompute — old pending entries are cancelled before anything new is
  scheduled.
- The notification card's content could be hidden on a locked device — it now
  declares public visibility.
- Muting from the card only dismissed the notification instead of muting one
  prayer occurrence — mute is now persisted and respected on both native and
  Flutter sides.

## [0.2.1] - 2026-09-21

First signed, releaseable build of Mawaqit for Android. This is a testing
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

- Notifications redesigned to match the Stitch reference: Mawaqit badge + APP
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
[0.3.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.2.1...v0.3.0
[0.3.1]: https://github.com/Abdogouhmad/mawaqit/compare/v0.3.0...v0.3.1
[0.3.2]: https://github.com/Abdogouhmad/mawaqit/compare/v0.3.1...v0.3.2
[0.4.1]: https://github.com/Abdogouhmad/mawaqit/compare/v0.3.2...v0.4.1
[0.4.2]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.1...v0.4.2
[0.4.3]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.2...v0.4.3
[0.4.4]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.3...v0.4.4
[0.4.5]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.4...v0.4.5
[0.4.6]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.5...v0.4.6
[0.5.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.4.6...v0.5.0
[0.6.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.5.0...v0.6.0
[0.7.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.6.0...v0.7.0
[0.8.2]: https://github.com/Abdogouhmad/mawaqit/compare/v0.7.0...v0.8.2
[0.8.3]: https://github.com/Abdogouhmad/mawaqit/compare/v0.8.2...v0.8.3
[0.8.4]: https://github.com/Abdogouhmad/mawaqit/compare/v0.8.3...v0.8.4