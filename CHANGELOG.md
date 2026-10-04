# Changelog

> **This file is the single source of truth for release notes.** The GitHub
> release workflow (`./build.sh --release-notes` → `.github/workflows/
> release.yml`) extracts the matching `## [<version>]` section and uses it
> verbatim as the release body. Every user-visible change MUST be recorded
> here — plain Keep a Changelog, one bullet per user-visible change.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.12.1] - 2026-10-04

Patch release. The highlights are the bottom navigation and a smaller download.

### Changed

- **The bottom navigation is frosted glass again** — the bar's tint no longer
  carries a colour cast, so it reads as a pane in front of the content instead of
  a green object resting on it, and the blur behind it is now strong enough to
  actually show. It also sits a little further from the screen edges.
- **Smaller download** — Android system strings are now packaged only for the
  languages the app ships in (Arabic, English, French) instead of all ~80 that
  the platform libraries provide.

### Removed

- **The Qibla screen** — the compass-based direction finder has been taken out
  pending a rewrite. It was the least stable part of the app and the readings were
  not reliable enough to rely on for prayer direction.

### Fixed

- **Notification sounds resolve correctly** on every build now, instead of only
  on the variant that appended an application-id suffix.

## [0.12.0] - 2026-10-03

New since v0.11.1.

A rebuilt Times tab. The previous one squeezed five prayer times across a phone
screen by shrinking them until they were about 40% of the intended size — and
about 22% at large text settings, which is when the screen is hardest to read.
The month is now a list of days rather than a squeezed table.

### Added

- **A "month at a glance" card** — how far each prayer moves across the month, in
  minutes, with an arrow for the direction. It is the question a monthly prayer
  table exists to answer, and reading it off the table meant comparing two cells
  nineteen rows apart on a phone.
- **Prayer names that stay on screen** — the labels are pinned above the month, so
  the times are never bare numbers. They are laid out from the same column
  measurement as the values, so the two cannot drift apart.
- **A month and year picker** — jump to a specific month instead of tapping the
  chevron repeatedly. It offers the same range the chevrons do.
- **A spoken summary per day** — a screen reader now announces each row as
  "Friday, March 14, today, Fajr 5:12 AM, Sunrise 6:31 AM, …" rather than reading
  seven unrelated numbers.

### Changed

- **The month is no longer a five-column table.** Each day is a row with the
  weekday, Gregorian date and Hijri date, and the prayer times are laid out in
  however many columns the screen can hold at full size — five on a wide phone,
  two on a narrow one at 200% text. Times are no longer scaled down to fit.
- **Days are wider apart and easier to hit**, and today is marked with one filled
  shape instead of three competing highlights.
- **The month opens on today** rather than on the 1st. On the 20th the 1st is
  nineteen rows above the fold.

### Fixed

- **Prayer times were unreadable at large text settings.** Five times sharing a
  360dp phone meant each was rendered at roughly 40% of its intended size, and at
  200% text roughly 22%.
- **Weekdays were abbreviated to fit, and clipped in Arabic.** Arabic has no
  abbreviated weekday form, so the date was being cut off on every row. Weekdays
  are now spelled out.
- **The "pull down to try again" message on a failed load had nothing to pull
  down.** There is now a Retry button.
- **Tapping a month could land on a month the calendar refuses to page to.** The
  bounds are now enforced at the one place the month is set, rather than relying
  on each control disabling itself.
- **The "month at a glance" card no longer stays hidden.** It compares each
  prayer's time on the first day of the month with its time on the last, and was
  subtracting the two dates as well as the times — about 43,200 minutes, which is
  not a change any prayer makes. The card read as untrustworthy and was never
  drawn at all. It now compares the times of day, so a prayer crossing midnight
  reads as the minutes it moved rather than as a 24-hour jump.
- **A clean error at launch** — the app started inside a guarded zone while the
  Flutter bindings were created outside it, so the two disagreed about which zone
  every timer, platform channel and image decode would run in.
- **A missing plugin no longer logs an error on every launch** — where there is no
  native side to answer (a stale install, desktop, web) the app now checks first
  instead of subscribing to a widget channel that cannot open.

## [0.11.1] - 2026-10-03

Fixes for the palette picker and the home-screen widget.

### Fixed

- **Tapping the home-screen widget no longer shows a white screen** — on Android
  14 and newer the tap was delivered to the app as a background activity start
  with no allowance for one, so Android refused it and you were left looking at
  a blank window instead of the app. The card now opens the app on the prayer
  times tab it was already showing, whether the app was closed or already open.
- **The home-screen widget wears the app's colour again** — it was still
  rendering in an older sage green while the rest of the app had moved to
  emerald, because the card's colours are baked into generated native code that
  was never regenerated after the palette changed.
- **The five prayer dots on the widget now move** — which prayers have passed
  and which one is next were never written to the widget, so every dot stayed at
  its faintest shade permanently. They now track the day like the rest of the
  card.
- **The selected tab and the tinted highlights follow the palette you pick** —
  choosing Sage or Midnight changed the icons and accents but left the filled
  pill behind the selected tab, the countdown hero, the adhan card, the qibla
  dial, the Times highlight and the update card all in emerald green, as though
  the choice had not been made.
- **The app can no longer get stuck on a blank window at launch** — if a
  platform plugin failed to answer during start-up the app would wait forever
  without drawing anything. A missing version string now degrades to a fallback
  instead of taking the whole launch down with it.
- **The version line under Settings is translated** — it was hardcoded to the
  English wording, so Arabic and French readers saw it in English while the
  About panel directly above it was translated.

### Changed

- **About Mawaqit finally describes the app** — the panel opens on the app's
  mark above its name, the tagline and a plain description of what the app does,
  and the version in a quiet chip underneath, all centred rather than hung off
  the left edge.

## [0.11.0] - 2026-10-03

New since v0.10.0.

### Added

- **French** — the app now speaks French throughout, not just in English and
  Arabic. The language picker in Settings → Appearance offers *System default*,
  English, العربية and Français, and the month and date headings, the prayer
  names and the countdown units all follow the choice.
- **Hijri dates on the Times tab** — every row now carries the Hijri day
  alongside the Gregorian one, so Ramadan, Eid and the rest of the Islamic year
  can be read straight off the calendar instead of counted backwards. The
  conversion follows the Umm al-Qura calendar, the same one printed prayer
  timetables use, so the dates match the mosque's.
- **Page through the month** — the arrows either side of the month step back and
  forward, a year at a time, and a button beside them brings you straight back to
  the current month.
- **Times opens on today** — landing on the 1st meant starting a screen of days
  that had already passed.

### Changed

- **The prayer names are readable again** — the column headings had been cut to
  three letters to make them fit, which turned *Fajr* into "Faj" and *Sunrise*
  into "Sun". They are spelled out now, and each row also carries its weekday so
  you can pick out the Fridays at a glance.
- **Today is easier to pick out** — the current day is marked with a highlighted
  band and an accent bar instead of a barely-visible tint, and the prayer
  headings stay pinned in place while you scroll the month.
- **The navigation bar is frosted again** — it had been rendering as a flat
  tinted slab, because the blur was sampling an empty backdrop rather than the
  list scrolling past underneath it.
- **The selected tab now wears the app's colour** — it was using a desaturated
  grey-green that belonged to no other part of the screen, so the tab you were on
  did not read as selected. It is now the emerald of the brand, and the app's
  colour roles are set explicitly instead of inheriting a shade of purple that
  Flutter supplies by default.

### Fixed

- **Text running off the edge of the Home screen** — the prayer time and the
  sunrise/sunset lines were laid out at their full width regardless of the
  screen, so on a narrow phone they spilled past the card and off the display.
- **The Settings language row overflowing** — the four options did not fit
  across a small screen and were cut off mid-word.
- **A row of text no longer breaks the layout at large font sizes** — every tab is
  now checked at up to 200% text, where five prayer times no longer fitted their
  columns.
- **Settings no longer shows a back arrow and a Done button** — both did nothing.
  Settings is one of the tabs at the bottom, so there is no screen to go back to;
  the tab bar is the way out.
- **The settings icon is gone from the Home header** — it opened a tab you can
  already reach from the bar along the bottom.
- **The compass now says why it cannot show a needle** — it distinguishes a phone
  with no magnetometer from a build whose compass support never registered, and
  shows a readable message instead of a raw error string.

## [0.10.0] - 2026-09-27

New since v0.9.0.

### Added

- **Arabic, properly** — the whole app is now translated: home, Settings, the
  adhan screen, the update screen, the notification cards and the home-screen
  widget. Arabic mirrors the entire layout right-to-left, and the clock, the
  Gregorian and Hijri dates and the countdown units all follow the chosen
  language instead of staying in English.
- **A language picker** — Settings → Appearance chooses *System default*,
  English or العربية, so you no longer have to change the whole phone's
  language to read the app in Arabic. Notifications and the home-screen widget
  follow the choice too, even on a phone whose system language is different.
  On Android 13+ the app also shows up in the system's own per-app language
  picker.

### Changed

- **Arabic is typeset in a real Arabic typeface** — the app's Latin font has no
  Arabic letters at all, so every Arabic string had been quietly rendered in
  whatever font your phone happened to use, which clashed with the rest of the
  screen. A proper Arabic companion face now ships with the app, and the
  letter-spacing tuned for Latin is dropped in Arabic, where spacing between
  letters breaks the way Arabic words join together.

### Fixed

- **Times follow your phone's clock setting** — every time in the app was
  hardcoded to a 12-hour `h:mm a`, so an 18:30 Isha showed as "6:30 PM"
  everywhere on a phone set to 24-hour, including in the notification text.
- **A failed settings write no longer lies to you** — a setting was shown as
  saved before the write to disk had actually succeeded, so a phone that ran out
  of space (or had storage permission revoked) silently reverted it on the next
  start. The new value is only shown once it is really stored.
- **A phone set to a language Mawaqit doesn't ship no longer risks a crash** —
  anything outside English and Arabic now falls back to the nearest supported
  language instead of failing.
- **Tomorrow's Fajr is scheduled** — the day's alarms stopped at Isha, so the
  first prayer of the next morning was missing until something else rescheduled.
- **Your chosen city is used for background alarms** — alarms armed while the
  app was closed calculated from GPS instead of the city you picked in Settings.
- **A test adhan can't ring alongside a real one** — the two shared a
  notification id, so firing a test could silence or replace a scheduled prayer.
- **Device tones can be previewed before you pick them**, and a preview that
  fails to play now falls back to a silent card instead of leaving you guessing.
- **The "Test" label on a test adhan is translated**, instead of appearing in
  English inside an Arabic notification.

## [0.9.0] - 2026-09-26

New since v0.8.6.

### Fixed

- **The adhan no longer looks like you started playing music** — the ringing
  adhan was carried by a media-playback service, so Android treated the call as
  a track: the tray card grew playback controls, it turned up in the media
  output switcher, and it took over the lockscreen as a media card. It is now an
  ordinary alarm, which is what it always was.
- **The full-screen adhan is no longer overwritten before it can appear** — the
  alarm used to post its full-screen card and then be handed a second,
  media-player-styled card under the same id a few milliseconds later, which
  threw the full-screen request away and left the card as the only thing you
  saw. There is now exactly one card for a ringing adhan, and it is the one that
  asks for the screen.
- **The adhan survives a reboot or an update** — Android clears every scheduled
  alarm when the app is replaced, and nothing put them back until the next
  12-hourly background run, so a phone that restarted in the morning could reach
  the evening with no adhan scheduled at all. Today's adhans and reminders are
  now re-armed as soon as the phone boots, and again after an in-app update.

### Added

- **"Display over other apps" in Alarm reliability** — a new row that lets the
  adhan take the screen *while you are using the phone*, not just when it is
  locked. Android deliberately downgrades a full-screen notification to a
  heads-up card the moment the screen is unlocked, and blocks an app from
  opening its own alarm screen from the background, so this is the one switch
  that lets the adhan interrupt what you are doing. It is off by default, it is
  never asked for on launch, and every other part of the alarm — the call, the
  timing, the lockscreen takeover — works exactly as before without it.
- **A more honest "Test adhan" message** — the test now says which of the two
  takeovers the current setup can actually perform, and points at the new row
  when the phone is in use.

## [0.8.6] - 2026-09-26

New since v0.8.5.

### Added

- **One-time ask to lift the battery restriction** — on first install and after
  every update, Mawaqit explains that your phone freezes apps while the screen is
  locked (the usual reason the adhan rings late or not at all) and offers to
  switch off battery optimisation, which hands you the system dialog to confirm.
  It asks once per version, never nags, and "Not now" leaves the row in
  Settings → Alarm reliability waiting for you.
- **Force the adhan through silent mode** — Mawaqit can now ask for *Do Not
  Disturb access*: while an adhan rings, the phone is put in "alarms only" so
  the call is still audible on a silenced device, and your own mode is restored
  the moment the adhan stops (or the process dies mid-call).
- **An "Alarm reliability" block in Settings** — one row per system access the
  adhan needs (Notifications, Alarms & reminders, Full-screen notifications,
  Do Not Disturb access, Unrestricted battery) with a live *Allowed* / *Fix*
  state. Tapping a row opens the exact system screen that grants it, and when
  you come back today's adhans and reminders are re-armed with the new access.
- **Battery-optimisation exemption** — Settings can now offer Mawaqit an
  exemption from Doze, which is what OEM power managers use to delay (or drop)
  alarms on stricter phones.

### Changed

- **The home countdown card is rebuilt** — the "NEXT PRAYER" marker is now a
  soft asymmetric badge, the prayer name sits on its own line above the numerals
  with the clock and the elapsed-since-last-prayer line tucked into a chip
  beneath it, and the day-progress bar lives in its own outlined surface with
  quieter (and quicker) animation, so the time itself is the only thing that
  moves.
- **One row replaced a dialog** — the old "Notification Permission" row in
  Settings is gone; the "Alarm reliability" block takes its place and reports
  each access separately instead of asking for everything at once and reporting
  a single verdict.

### Fixed

- **The pre-prayer reminder no longer goes missing** — the decorated countdown
  card is now always armed through the native exact-alarm engine on Android
  (which quietly falls back to an inexact alarm when needed) instead of being
  skipped whenever a permission read came back late or unanswered, and its
  settings are written to disk *before* the alarm is armed — a reschedule that
  lost that write used to drop the card entirely, with no error anywhere.
- **The card can no longer post into a channel that isn't there** — the channel
  travels with the reminder itself and is (re)created at post time, so a missing
  channel no longer swallows the notification silently.
- **Permission prompts can no longer stall the scheduler** — a system dialog
  whose result never arrives no longer leaves the day's notifications
  unscheduled, and the background reschedule no longer prompts at all.
- **A reminder that arrives without stored data still shows** — the alarm
  carries its own copy of the reminder, so a card is posted even if the stored
  entry is gone.

## [0.8.5] - 2026-09-25

New since v0.8.4.

### Changed

- **The adhan screen now comes to Android** — prayer-time and test alarms raise
  the same presenter you see on desktop (over the lockscreen, with the live
  clock and Stop button) instead of a separate native alarm activity, so the
  design, theme and behaviour match on every device.
- **The lockscreen takeover rides on the main window** — while an alarm rings
  the app keeps the display on and shows over the lockscreen, and the old
  dedicated alarm activity (with its theme, strings and drawables) was retired.

### Fixed

- **The adhan rings once, then stops by itself** — the call no longer loops
  forever: it plays through a single pass and the presenter closes itself when
  it ends. One tap of Stop (or either volume key) still silences it instantly.
- **Stopping the alarm always closes the presenter** — silencing from the tray
  card or a volume key now dismisses the in-app adhan screen too, and firing a
  test back-to-back replaces the ringing screen instead of stacking another on
  top of it.

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
[0.8.5]: https://github.com/Abdogouhmad/mawaqit/compare/v0.8.4...v0.8.5
[0.8.6]: https://github.com/Abdogouhmad/mawaqit/compare/v0.8.5...v0.8.6
[0.10.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.9.0...v0.10.0
[0.11.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.10.0...v0.11.0
[0.11.1]: https://github.com/Abdogouhmad/mawaqit/compare/v0.11.0...v0.11.1
[0.12.0]: https://github.com/Abdogouhmad/mawaqit/compare/v0.11.1...v0.12.0