# Testing Mawaqit

Two layers: **automated** (fast, runs in CI) and **manual on-device** (the only
thing that can prove the adhan actually rings). The alarm/notification core is the
app's whole reason to exist and is the least covered by unit tests, so the manual
matrix below is not optional before a release.

Everything here was written against the code as it stands (`notification_service.dart`,
`AdhanScheduler.kt`, `AlarmAccess.kt`). If a behaviour changes, update this file in
the same PR.

---

## Automated

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage        # lcov at coverage/lcov.info
```

CI (`.github/workflows/ci.yml`) runs exactly these on every pull request and every
branch push, plus a debug-APK smoke build. A release additionally needs the manual
matrix.

---

## Manual on-device matrix (before each release)

Use a **release-signed** build installed over the previous one, not a debug hot
reload — several failure modes only appear once the process can be killed.

```bash
./build.sh                 # signed release APKs under dist/
adb install -r dist/mawaqit-v<version>-universal.apk
```

Set `PKG=com.freesoftware.mawaqit` for the commands below.

### 0. Preconditions (grant, from Settings → Alarm reliability)

The app surfaces each of these; grant all of them so the matrix tests the target
state, then repeat spot-checks with one removed:

| Access | Player system settings screen | Why it matters |
|---|---|---|
| Notifications | App notification settings | nothing posts without it |
| Alarms & reminders | `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` | exact delivery |
| Full-screen intents | `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` | lockscreen takeover (Android 14+) |
| Display over other apps | `ACTION_MANAGE_OVERLAY_PERMISSION` | takeover while unlocked |
| Do Not Disturb access | Notification policy access | "Force the adhan" lifts silent mode |
| Battery: Unrestricted | `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | keeps AlarmManager out of OEM Doze delays |

### 1. In-app trigger (fast smoke test)

Settings → Notifications → the **Adhan** block → **Test** (and likewise the
**Pre-Prayer** block). Both fire about **3 seconds** later. The adhan test is
routed through the native exact-alarm engine, so it exercises the real path, not a
Flutter timer.

Expect, with the screen **locked/off**: the adhan audio plays and the full-screen
adhan card appears over the lockscreen; the notification's **Stop** action and the
in-app **Stop** both silence it. With the screen **unlocked**: a heads-up card,
and the full-screen presenter *only* if "Display over other apps" is granted —
otherwise the card alone is correct, not a failure (the app says so up front in
the subtitle).

### 2. Real delivery, one case at a time

For each, set the device clock so a prayer is ~2 minutes away, lock the phone, and
wait. Prefer the earliest prayer of the day to keep the wait short.

| # | Scenario | Steps | Pass condition |
|---|---|---|---|
| 1 | Screen off | Lock the phone, wait for the adhan | audio plays; lockscreen card visible; Stop works |
| 2 | App killed | `adb shell am force-stop $PKG`, wait | same as #1 — process death must not matter |
| 3 | Doze | `adb shell dumpsys deviceidle force-idle`, wait, then `adb shell dumpsys deviceidle unforce` | adhan still fires on time |
| 4 | Reboot | `adb reboot`, then wait for the next prayer | alarms re-armed by `BootReceiver`; adhan fires |
| 5 | App updated | `adb install -r <apk>` over the running app | `MY_PACKAGE_REPLACED` re-arms; adhan fires |
| 6 | Timezone change | Settings → change timezone, reopen the app, wait | see note below — **known soft spot** |
| 7 | Pre-prayer lead | set lead to 5/10/15 min, wait | the promoted live countdown appears exactly that many minutes before, chip/chronometer counting down, progress filling |
| 8 | Airplane mode | enable airplane mode, wait | on-device times still fire (no network needed) |
| 9 | Muted prayer | mute one occurrence from its card | muted occurrence stays silent but still posts its card |
| 10 | DND / silent | enable silent or DND, wait | with DND access granted, "Force the adhan" rings anyway and restores the mode after Stop |
| 11 | Live update actions | tap **Prayed** / **Dismiss** on the countdown card, then reschedule (toggle a setting) | card retires and does not come back for that occurrence; the next prayer still gets its own card |
| 12 | Live update at prayer time | wait out the countdown | card flips to "It's time for …" with **Prayed** / **Dismiss** and removes itself after 30 min |
| 13 | Live update from a cold stop | `adb shell am force-stop $PKG`, then cross the lead boundary | card still posts and ticks (native `AlarmManager`, not a Dart timer) |

> **Android 16+ promotion.** On the countdown card, verify the status-bar chip and
> the top-of-shade/lockscreen placement; the chip label reads "{prayer} · {n}m" and
> refreshes about once a minute. On older Androids the same card must render as a
> standard ongoing notification with a progress bar — never an empty or
> promotion-blocked card. `adb shell dumpsys notification --noredact | grep -i
> requestPromoted` shows the promotion extras; the system still decides whether to
> promote.

> **Known gap — time/timezone changes.** The schedule is rebuilt when the app runs,
> by the 12-hourly WorkManager periodic task (`background_scheduler.dart`), and by
> `BootReceiver`, which handles reboot, in-place update, `TIME_SET` and
> `TIMEZONE_CHANGED`. A device whose clock or timezone moves while the app stays
> closed is re-armed by that receiver; if the re-arm cannot compute today's times it
> still degrades to the periodic task. Treat scenario #6 failing *without* a re-arm
> as a regression.

### 3. Overlay / Stop

- Stop from the notification action, from the in-app button, and with the volume
  key — all three must silence the clip and dismiss the card (`AdhanScheduler.stopActive`).
- "Test" twice in a row must ring the second time (the single-audio guard is
  bypassed for tests — `Schedule.isTest`).

### 4. Inspecting failures

```bash
adb logcat | grep -iE "AdhanScheduler|AdhanPlaybackService|AdhanAlarmReceiver"
adb shell dumpsys alarm | grep -A3 $PKG      # is the alarm actually armed?
adb shell dumpsys deviceidle whitelist | grep $PKG
```

`AdhanScheduler` logs a warning when the alarm-clock arm (`setAlarmClock`) had to
fall back (exact-alarm access missing) or when `USE_FULL_SCREEN_INTENT` is denied — those two
lines explain most "it didn't ring" reports.

### 5. OEM spot-checks

On at least one aggressive-OEM device (Xiaomi/Huawei/Oppo/Samsung), run scenarios
1–4 after using the app's autostart/battery guidance. These builds are where the
battery-optimisation exemption is not sufficient on its own.

---

## Coverage

`flutter test --coverage` writes `coverage/lcov.info`; CI uploads it as an
artifact. Current line coverage is in the thirties and the alarm/notification core
is the low end of that (`notification_service.dart`). Raising it — and eventually
splitting that file — is tracked in `docs/optimization-notes.md`.

---

## 1.0.0 feature matrix (manual, on device)

The sections above cover the alarm core. 1.0.0 adds five surfaces that CI can
only partially exercise; run these on a physical device before cutting stable.
Record the result in [`on-device-smoke-1.0.0.md`](on-device-smoke-1.0.0.md).

### 6. Qibla & travel

- [ ] Qibla tab shows a bearing from the saved home coordinates with the
      compass moving; rotating the device brings the Kaaba-tipped needle into
      the gold gate at the top of the dial and confirms "Facing the Qibla".
- [ ] With the compass covered/unavailable (or on a host without a sensor), the
      screen says so honestly and still shows the numeric bearing.
- [ ] Switching on travel search and picking a city shows the travel banner on
      Home and Times; the bearing and prayer times change to the temporary city.
- [ ] "Return home" restores the saved home city/GPS exactly; the travel city is
      not written into the shared location cache (verify via Settings → coords).
- [ ] Airplane mode: searching a new city fails with a readable message and the
      existing travel override is left untouched.

### 1.1.0 Qibla regression checks

These target the four beta reports (wrong needle, wrong bearing/distance,
jitter, compass never appears). Do them on a physical Android phone and, if one
is available, an iPhone.

- [ ] **True north:** stand facing a landmark whose true bearing from your
      current position is known (a map app with declination shown works). The
      needle must agree with the *true* bearing, not the magnetic one — after
      1.1.0 the app adds the WMM declination on Android.
- [ ] **Known bearing:** at the Kaaba the distance reads 0 km and the bearing
      wraps without jumping; from Rabat the bearing is ≈ 89° and the distance
      ≈ 4,730 km.
- [ ] **Travel:** set a travel city with times still on Home; the Qibla bearing
      and distance change immediately, while Settings still shows the saved home
      coordinates. "Return home" restores them exactly.
- [ ] **Jitter:** rotate slowly through north (359° → 1°). The needle takes the
      short route and glides; it never spins a full turn at the seam.
- [ ] **Calibration:** with the sensor unreliable (Android accuracy unknown)
      the screen says "calibrate" instead of silently trusting a bad heading.
- [ ] **Recovery:** background the app for a minute, return to the Qibla tab,
      and confirm the needle resumes. Covering the sensors must return to the
      honest "unavailable" state without crashing the tab.
- [ ] **Accessibility:** with TalkBack on and 200% text, the dial announces the
      bearing and sensor state once; the travel search outcome is announced as a
      live region; reduced motion removes the needle animation.

### 1.1.1 Qibla redesign checks

The redesigned instrument replaces the arrow-only glance with quantified turn
guidance and an explicit aligned state. Repeat these on Android and iOS before
the next stable pass.

- [ ] **Turn guidance:** standing away from the Qibla, the status line says
      "Turn N° left/right" and the number counts down as the phone turns. The
      gold gate stays fixed at screen-up; the needle moves, not the dial.
- [ ] **Alignment:** inside ±5° with a trustworthy compass, the dial frame turns
      gold, the beam fills, and the line reads "Facing the Qibla". At 6–10° off
      it must still ask for a turn — never claim alignment early.
- [ ] **Honesty:** with the compass calibrating or unavailable, the gold frame
      and "Facing the Qibla" never appear even if the needle happens to sit at
      the top. The bearing and distance readouts remain correct.
- [ ] **Reading the instrument:** the Kaaba cube at the needle tip is identified
      by the legend under the dial; bearing and distance are legible in both
      themes at 1× and stack into rows at 200% text.
- [ ] **Localisation:** EN/FR/AR strings for the turn hints, alignment state and
      readouts are present; RTL layout has no clipping at 360/388dp and 2× text.

### 7. Widget 2.0

- [ ] Add both 2x2 and 4x2 widgets in light, dark and AMOLED themes; text is not
      clipped and the muted dot is the only tinted element on AMOLED.
- [ ] Arabic widget labels come from the locale, not stale cached data.
- [ ] Tapping the widget opens the Times tab with no white/light flash.
- [ ] In the in-app widget configuration screen, "Open Times" and "Silence
      adhan" quick actions work; the widget root tap still goes to Times.
- [ ] After an OTA update the widget survives and shows the new day's times.

### 8. Insights & Hijri cards (Times tab)

- [ ] Tapping "prayed" on a few occurrences updates the monthly total, on-time
      rate and streak, and the marks survive a full app restart.
- [ ] Clearing app data removes all marks (local-only, no account or sync).
- [ ] Paging the Hijri calendar moves between months; today and events are
      emphasised; the Gregorian mapping matches the system calendar.
- [ ] At 200% text in AR/FR/EN at 360dp and 388dp, neither card overflows.

### 9. Update channels (stable / beta)

- [ ] Install a signed stable APK; OTA banner offers only stable builds.
- [ ] Switch to beta in Settings → Update center, confirm the beta release is
      found and installs with its own SHA-256 verification.
- [ ] Switch back to stable; no settings, marks or location are lost.
- [ ] Start a download, attempt a channel switch mid-download: the toggle is
      disabled and the notifier refuses the change.
- [ ] Corrupt the downloaded APK (or the manifest checksum) and confirm the
      install is blocked — fail-closed on both channels.

### 10. Accessibility pass (all tabs and dialogs)

- [ ] TalkBack announces every interactive element (nav tabs, prayer rows,
      mute/silence, widget config, channel selector, calendar pager).
- [ ] Focus order follows reading order in EN/FR and right-to-left in AR.
- [ ] System font at 200% on every tab and dialog at 360dp: no clipping or
      overlapping text; reduced-motion and transparency settings do not break
      the adhan overlay.
- [ ] All palettes incl. AMOLED meet the ratios in `docs/contrast-report.md`.

### 11. Local midnight & clock changes

- [ ] Leave the app closed across local midnight with the phone awake; verify
      via `adb shell dumpsys alarm` that the new day's alarms are armed.
- [ ] Change the clock/timezone; alarms re-arm at the correct local times.
