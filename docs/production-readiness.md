# Production readiness — Mawaqit (Android)

How close the app is to a shippable production release, and what actually stands
in the way. This file is maintained alongside [`roadmap.md`](roadmap.md) and is
refreshed at each version bump. Claims about code cite the file they were read
from; claims about a build or a test run are made only after the full
verification matrix in [`testing.md`](testing.md) is green.

Companion to [`optimization-notes.md`](optimization-notes.md), which covers the
performance/quality work; this file answers a narrower question: *what is between
here and a release a stranger can install and keep?*

---

## TL;DR (1.0.0)

The **Android release path is production-grade.** Signing, shrinking, versioning,
the automated release, both OTA channels and CI are done and self-checking.

**Distribution decision (1.0.0): GitHub/APK sideload.** The app ships an in-app
self-updater (`ota_update` + `REQUEST_INSTALL_PACKAGES`), which Google Play
policy forbids. Play remains a separate, deliberately out-of-scope project that
would require removing the updater and its permission. See the decision below.

The one remaining risk is **device-only behaviour**: the alarm/notification core
is exercised by pure policy tests and a manual on-device matrix
(`docs/testing.md`), not by CI. The 1.0.0 matrix adds Qibla/travel, the widget,
15-minute insights and both OTA channels; it is recorded in
`docs/on-device-smoke-1.0.0.md` once a physical pass is done.

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

**Decision (1.0.0): keep GitHub/APK sideload.** The pipeline already ships it,
and the in-app updater (now with a user-visible stable/beta switch) is a headline
feature of this release. Play is a separate, scoped project only if discovery
becomes a goal; it would remove the updater and its permission.

---

## Risk register

| Risk | Severity | Where | Mitigation |
|---|---|---|---|
| Alarm/notification core under-tested | High | `lib/data/services/notification_service.dart` | Manual on-device matrix (`docs/testing.md`); pure policy tests + device pass |
| Adhan uses `setExactAndAllowWhileIdle`, not `setAlarmClock` | Medium | `AdhanScheduler.schedule()` | Native engine deliberately unchanged for 1.0.0; see "Reliability observations" |
| OEM battery killers silently drop adhans | High | Doze/Xiaomi/Huawei/Oppo/Samsung | Onboarding requests exemption + autostart hint; in-app reliability checks |
| Self-updater vs Play | Decision (closed) | `ota_update`, manifest | GitHub sideload for 1.0.0; Play is a separate project |
| Bundled adhan recitations have no documented licence | Unknown → resolve | `assets/audio/*.mp3`, `res/raw/adhan_*.mp3` | See "Open questions" below |

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

- **`ACTION_DATE_CHANGED` is now registered (1.0.0).** The manifest and
  `BootReceiver.kt` include it alongside `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`,
  `TIME_SET` and `TIMEZONE_CHANGED`, so a date rollover while the app stays
  closed re-arms through the same `BootRescheduleWork` path as a reboot instead
  of waiting up to 12 hours for the periodic task.

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

## Release checklist (1.0.0)

**Required**

1. Channel decision: GitHub/APK sideload (closed above — no work).
2. Bump `version:` in `pubspec.yaml` **and** the matching `+<build>` (they must
   agree or `build.sh` fails).
3. Add a complete `## [<version>]` section to `CHANGELOG.md` (the release body is
   taken from it verbatim).
4. Run the full verification matrix:
   `dart format --set-exit-if-changed .`,
   `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`,
   `flutter build apk --debug`, `bash -n build.sh`,
   `./build.sh --detect-version` (must print the new tag/versionCode).
5. Record a physical-device pass of the matrix in `docs/testing.md` and
   `docs/on-device-smoke-1.0.0.md` (Qibla/travel, widget launch, both OTA
   channels, RTL/200% text, adhan on the lockscreen).
6. Fast-forward merge to `main` and push. The tag, APKs, checksums, release and
   `update_manifest.json` follow automatically; never push a tag by hand.

**Hygiene (does not block)**

7. Add real screenshots under `docs/screenshots/` and drop the README placeholder.
8. Fill the `TODO` contacts in `SECURITY.md` / `CODE_OF_CONDUCT.md`.
9. Resolve the adhan-recitation licence and credit it (see Open questions).

---

## Verdict

**Ship-ready for the GitHub/APK channel.** The heavy lifting — reliable exact
alarms, foreground-service adhan, the automated signed release with stable/beta
channels — is done and guarded by fail-closed checks. The honest caveat is that
the alarm core's correctness rests on a documented device pass rather than CI,
and that the app's self-updating design rules out Play unless that is
deliberately reworked.
