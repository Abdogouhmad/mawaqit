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
