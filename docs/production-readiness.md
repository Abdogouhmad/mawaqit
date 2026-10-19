# Production readiness — Mawaqit (Android)

How close the app is to a shippable production release, and what actually stands
in the way. This is a **static review** of the tree as of the branch
`chore/optimize-and-docs` — no build or test run was performed (per instruction),
so every claim below cites the file it was read from rather than a green check.

Companion to [`optimization-notes.md`](optimization-notes.md), which covers the
performance/quality work; this file answers a narrower question: *what is between
here and a release a stranger can install and keep?*

---

## TL;DR

The **Android release path is already production-grade.** Signing, shrinking,
versioning, the automated release, the OTA manifest and CI are all done and
self-checking. There is no missing plumbing to build.

The remaining gap is **not code, it is decisions and test depth**:

1. **Distribution is a fork in the road, and the app currently sits on the side
   that cannot go to Google Play** — it ships an in-app self-updater
   (`ota_update` + `REQUEST_INSTALL_PACKAGES`), which Play policy forbids. Either
   accept GitHub/APK sideloading as the channel (current, deliberate) or plan the
   work to remove the self-updater for Play.
2. **The alarm/notification core has single-digit test coverage.** It is the one
   thing the app cannot get wrong, and it is the one thing CI cannot exercise
   without a device.
3. A short tail of release hygiene (stale `docs/DECISIONS.md`, missing
   screenshots, TODO contacts).

None of (3) blocks shipping. (1) is a choice. (2) is a risk to *manage*, not a
gate — it is what manual on-device testing is for.

---

## Toolchain (verified from the tree)

| Piece | Value | Source |
|---|---|---|
| Flutter | 3.47.6 stable | `flutter --version` |
| Dart SDK constraint | `^3.13.4` | `pubspec.yaml` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle.kts` |
| Kotlin | 2.4.0 | `android/settings.gradle.kts` |
| compileSdk / targetSdk | 36 | `flutter.compileSdkVersion` / `targetSdkVersion` |
| minSdk | 24 (Android 7.0) | `FlutterExtension.minSdkVersion` |
| NDK | 28.2.13676358 | `FlutterExtension.ndkVersion` |
| Java | 17 | `android/app/build.gradle.kts` |

Targeting API 36 on a current stable Flutter with core-library desugaring on is
exactly where a new release should be. Nothing here is EOL.

---

## Release pipeline (verified — already done)

All of this is implemented and **fails closed**, which is the part that matters:

- **Signing** — `android/app/build.gradle.kts` reads `android/key.properties`
  (gitignored, confirmed untracked); `build.sh` provisions it from `WAQT_*`
  secrets and **refuses to build in CI without it** (`CI_RUNNER=true` → `exit 1`),
  so a release can never ship unsigned or debug-signed.
- **Signature verification** — `build.sh` runs `apksigner verify --print-certs`
  on every staged APK and fails the build if the SDK tool is missing in CI.
- **Shrinking** — `isMinifyEnabled` + `isShrinkResources` with
  `proguard-android-optimize.txt` and `android/app/proguard-rules.pro`
  (entry points pinned, Play Core `-dontwarn`).
- **Versioning** — `pubspec.yaml` is the single source of truth; Android's
  `versionCode` is derived as `major*10000 + minor*100 + patch`, and `build.sh`
  **fails the build if the literal `+<build>` in pubspec disagrees** with the
  derived value (the check that keeps F-Droid/regex consumers honest).
- **Release automation** — `.github/workflows/release.yml` runs on every push to
  `main`: builds split-per-ABI + universal APKs, extracts the `## [<version>]`
  section of `CHANGELOG.md` as the release body, tags `v<version>`, publishes the
  GitHub release, rewrites and commits `update_manifest.json` (fresh sha256, URL,
  notes, `publishedAt`). Publishing is isolated to this workflow.
- **CI** — `.github/workflows/ci.yml` runs `dart format --set-exit-if-changed`,
  `flutter analyze --fatal-infos --fatal-warnings`, `flutter test --coverage`, and
  a debug-APK smoke build, on PRs and on every branch push including `main`.
- **Manifest** — the permission set is deliberate and documented in-place
  (`AndroidManifest.xml`), including the `specialUse` foreground-service subtype
  used to justify the non-`mediaPlayback` FGS.
- **Hygiene** — no secrets tracked; no `assert(` in `lib/` (nothing
  logic-bearing stripped in release); no `localhost`/staging URLs; the only
  outbound URLs are the production raw-GitHub manifest and the mawaqit referer.

**Conclusion:** the next `git push origin main` of a bumped `pubspec.yaml` +
`CHANGELOG.md` produces a signed, verified, published release. The pipeline is the
fast part.

---

## The one decision that gates Google Play: distribution channel

The app self-updates. `lib/data/services/update_service.dart` polls
`update_manifest.json` from GitHub `main`, and `ota_update` + `REQUEST_INSTALL_PACKAGES`
let the app hand a downloaded APK to the package installer. `build.sh`'s own
comment states the intent: *"GitHub APK distribution, not Play."*

That is a coherent, legitimate choice — but it is **mutually exclusive with Google
Play**, which prohibits apps that install updates outside Play. So "fast
production" splits:

- **GitHub/APK channel (current).** Nothing to do — the pipeline already ships it.
  Cost: users must enable "install unknown apps"; store discovery is lost; the
  sideload audience must be found by other means.
- **Play channel.** Requires: removing the in-app updater and
  `REQUEST_INSTALL_PACKAGES`; Play Console declarations + review for
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `SYSTEM_ALERT_WINDOW`,
  `USE_EXACT_ALARM`/`SCHEDULE_EXACT_ALARM`, and the `specialUse` FGS; and a
  data-safety form. This is days, not hours, and it changes product behaviour
  (no self-update).

**Recommendation:** keep the GitHub channel for the next release — it is already
shippable — and treat Play as a separate, scoped project only if discovery is a
goal. Do not do it "on the way to" a release; it is its own release.

---

## Risk register

| Risk | Severity | Where | Mitigation |
|---|---|---|---|
| Alarm/notification core under-tested | High | `lib/data/services/notification_service.dart` (~1,930 lines, ~4% line coverage) | Manual on-device matrix (`docs/testing.md`); split the file only in a device-validated PR |
| Adhan uses `setExactAndAllowWhileIdle`, not `setAlarmClock` | Medium | `AdhanScheduler.schedule()` | See "Reliability observations" below |
| No receiver for `ACTION_DATE_CHANGED` | Low | `AndroidManifest.xml`, `BootReceiver.kt` | See "Reliability observations" below |
| OEM battery killers silently drop adhans | High | Doze/Xiaomi/Huawei/Oppo/Samsung | Onboarding already requests exemption + autostart hint; keep the in-app reliability checks |
| Self-updater vs Play (above) | Decision | `ota_update`, manifest | Choose a channel |
| Doctor/`flutter` version drift in CI | Low | workflows use `channel: stable` | Pin to a version if reproducibility is wanted |
| Stale `docs/DECISIONS.md` | Low | cites absent `feat.md`, removed Qibla/`flutter_compass` | Prune or refresh |
| Bundled adhan recitations have no documented licence | Unknown → resolve | `assets/audio/*.mp3`, `res/raw/adhan_*.mp3` | See "Open questions" below |
| `Nominatim` fallback identifies as `dev build` | Low | `lib/data/repositories/location_repository.dart:88` | Use a real UA/contact before scale |

### Reliability observations

- **The adhan alarm is scheduled with `AlarmManager.setExactAndAllowWhileIdle`,
  not `setAlarmClock`.** `AdhanScheduler.kt:203` uses the former, falling back to
  `setAndAllowWhileIdle` when exact-alarm access is missing. `setExactAndAllowWhileIdle`
  *does* fire in Doze, but the platform rate-limits it to roughly one delivery per
  app per ~9 minutes while idle, and it does not appear in the system's "next
  alarm" UI. `setAlarmClock` has neither limit and is the API Android's own docs
  point at for exactly this use case (an alarm that must ring). For five prayers a
  day the 9-minute throttle is not normally a problem — which is why this is a
  *medium*, not a *high* — but `setAlarmClock` is the stronger primitive the
  Kotlin-rewrite brief already calls for. **Not changed here:** it edits the single
  most reliability-critical call in the app and cannot be validated without a
  device, so it belongs in its own PR with the `docs/testing.md` matrix run before
  and after.

- **Nothing listens for `ACTION_DATE_CHANGED`.** The manifest registers
  `BootReceiver` for `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET` and
  `TIMEZONE_CHANGED`, so a clock correction or a timezone move re-arms through
  the same `BootRescheduleWork` path as a reboot. A device whose calendar date
  rolls over while the app stays closed still relies on the 12-hourly WorkManager
  periodic task (`background_scheduler.dart` →
  `registerPeriodicTask(..., frequency: Duration(hours: 12))`) to arm the new
  day's occurrences. Real-world impact is small — the date does not change on its
  own without an app launch or a periodic task in between for most users — but
  adding `ACTION_DATE_CHANGED` to the same receiver would close it.

### Open questions for the maintainer

- **Where do the three adhan recitations come from, and under what licence?** The
  app bundles `Adham Al Sharqawe.mp3`, `Hamza Al Majale.mp3` and
  `Mansur Al Zahrane.mp3` — full recitations whose filenames name real reciters —
  in both `assets/audio/` and `android/app/src/main/res/raw/`. Meanwhile
  `tool/gen_tones.py` opens with *"No third-party audio is bundled — every preset
  is synthesised here … licence-free"*, which is true of the short chimes
  (`tone_*.wav`) and of `tone_traditional_adhan.wav`, but not obviously of these
  three `.mp3`s. Nothing in `README.md` (Acknowledgements), `LICENSE` or a NOTICE
  file credits them. Before distributing widely, either add an attribution/licence
  note (they are the app's headline sound) or replace them with generated audio.
  This is the one finding here that the maintainer must answer; it cannot be
  resolved from the tree.

### Small findings from this pass

Concrete, low-risk items noticed while reading — none change runtime behaviour,
so they are listed rather than silently changed:

- **`lib/core/const/asset_paths.dart` is mostly stale.** `adhanDir =
  'assets/adhan/'` and `cities = 'assets/data/cities.json'` point at directories
  that do not exist (`assets/` contains only `audio/`, `fonts/`, `icons/`), and no
  code reads either constant. Its class comment also cites an
  `androidResources.noCompress` block that is not present anywhere in `android/`,
  and a `feat.md §4.4` that is not in the repo. The real adhan audio lives in
  `assets/audio/` and is named per tone in `lib/core/audio/tone_catalog.dart`.
  This pass added the one that is used (`appIcon`); the dead constants were
  pruned in 0.14.0, leaving only `appIcon`.
- **The Nominatim online city-search fallback sends
  `User-Agent: MawaqitPrayerApp/1.0 (prayer clock; dev build)`**
  (`location_repository.dart:88`). "dev build" is a leftover and, more
  importantly, OSM's Nominatim usage policy expects a genuinely identifying
  agent with a contact; an anonymous/placeholder UA can be throttled or blocked.
  Resolved in 0.14.0: the UA now names the project with a contact URL.

---

## Fast path to the next release (checklist)

Only the first block is required; the rest is hygiene.

**Required**

1. Decide the channel (default: GitHub — no work).
2. Bump `version:` in `pubspec.yaml` **and** the matching `+<build>` (they must
   agree or `build.sh` fails).
3. Add a `## [<version>]` section to `CHANGELOG.md` (the release body is taken
   from it verbatim).
4. Merge to `main`. The tag, APKs, checksums, release and `update_manifest.json`
   follow automatically.

**Before announcing it**

5. Run the manual matrix in `docs/testing.md` on a real device: screen off,
   Doze (`adb shell dumpsys deviceidle force-idle`), app swiped away, reboot,
   timezone change, airplane mode — for both adhan and pre-prayer, including the
   Android 16+ live-update promotion and its Prayed/Dismiss actions.
6. Confirm the release-secrets (`WAQT_*`) are present so CI does not refuse to
   sign.

**Hygiene (does not block)**

7. Fill the `TODO` contacts in `SECURITY.md` / `CODE_OF_CONDUCT.md`.
8. Add real screenshots under `docs/screenshots/` and drop the README placeholder.
9. Refresh `docs/DECISIONS.md` (the tracked `stitch_minimal_prayer_times_app/`
   bundle was removed in 0.14.0).
10. Pin `home_widget_generator` if the maintainer prefers a literal over `any`.
11. Resolve the adhan-recitation licence and credit it (see Open questions).
12. ~~Give the Nominatim fallback a real `User-Agent`~~ — done in 0.14.0.
13. ~~Prune the stale constants in `lib/core/const/asset_paths.dart`~~ — done in
    0.14.0.

---

## Verdict

**Ship-ready for the GitHub/APK channel today.** The heavy lifting — reliable
exact alarms, foreground-service adhan, the automated signed release — is done and
guarded by fail-closed checks. The honest caveats are that the alarm core's
correctness rests on device testing rather than CI, and that the app's
self-updating design rules out Play unless that is deliberately reworked.
