# Optimization notes

Working notes produced during the `chore/optimize-and-docs` pass. They are the
basis for the final report: baseline vs. after, what changed and why, what was
deliberately skipped, and what still needs a maintainer's decision.

Environment: **Flutter 3.47.6 (stable)**, **Dart 3.13.5**.

## Baseline vs. after

| Check | Before | After |
| --- | --- | --- |
| `dart format --set-exit-if-changed .` | 8 files reformatted | clean |
| `flutter analyze` | 0 issues (default `flutter_lints`) | 0 issues (stricter ruleset, `--fatal-infos`) |
| `flutter test` | 129 passed / **25 failed** | 164 passed / 0 failed |
| `flutter pub outdated` (direct + dev) | 6 patch/minor behind | all up-to-date |
| Release shrinking | `isMinifyEnabled` + `isShrinkResources` on | unchanged (already correct) |

The 25 failing tests were pre-existing and are documented below.

## What changed, by category

### Static analysis & code quality (2.1)

- `analysis_options.yaml` now enables, on top of `flutter_lints`: const/
  immutability rules (`prefer_const_constructors`, `prefer_const_declarations`,
  `prefer_const_literals_to_create_immutables`, `prefer_final_locals`,
  `prefer_final_fields`) and correctness/hygiene rules (`unawaited_futures`,
  `use_build_context_synchronously`, `avoid_print`, `avoid_unnecessary_containers`,
  `sized_box_for_whitespace`, `unnecessary_lambdas`, `use_super_parameters`,
  `directives_ordering`, `sort_child_properties_last`, `unnecessary_this`,
  `avoid_redundant_argument_values`).
- Enabling those rules surfaced **132** infos. `dart fix --apply` resolved 118
  mechanically; the remaining `unawaited_futures` (3) were fixed by hand with
  `unawaited(...)` on genuinely fire-and-forget futures (a Linux CLI player's
  `exitCode` handler and two `HapticFeedback.selectionClick()` calls).
- No `print(` exists in `lib/`; diagnostics already go through `debugPrint`/
  `dart:developer`, so no logging change was needed.

### Bug fixes found while making the suite green (2.6 + behavior)

These are the only behavior-affecting changes, and each is a fix, not a change
of intent:

- **Solar-card overflow on the Times tab** — `lib/features/times/widgets/solar_arc.dart`
  laid the sunrise/sunset anchors out with `Spacer`s inside a `Row`, which handed
  the anchor labels an unbounded width and overflowed on narrow phones and at
  large text scales (the root cause of 12 `tab_layout_test` failures). Replaced
  the two spacers with two `Expanded` anchors. Verified at 360/388 dp × ar/en/fr
  × 1.0/1.5/2.0 text scale.
- **Locale fallback picked the wrong language** — `lib/l10n/ambient_l10n.dart`
  fell back to `AppLocalizations.supportedLocales.first`, which is `ar` because
  the generated list is alphabetical, not the template (`en`). A locale-less
  context would therefore resolve Arabic. Added `const Locale kFallbackAppLocale =
  Locale('en')` and used it in `resolveLocalizations` and `supportedLocaleFor`.

### Tests (2.6)

- Repaired the 25 outdated/flaky tests that assumed an older Flutter/intl or an
  unsupported language: localization delegates are now pumped explicitly in the
  alarm-access widget tests, `intl` date formatting is initialized in the
  formatter test, the "unsupported language" guard test uses `zh` (French is now
  supported), and the bottom-nav test expects the real Settings tab index.
- Added `test/update_service_test.dart` (10 tests) covering the OTA
  `UpdateManifest` parsing and the `UpdateService.check` decision matrix, which
  were previously untested core logic.

### Dependencies (2.4)

- `flutter pub upgrade` brought every direct and dev dependency current within
  existing constraints (patch/minor bumps for `flutter_local_notifications`,
  `flutter_timezone`, `package_info_plus`, `shared_preferences`, `timezone`,
  `intl`, plus transitive updates). `flutter pub outdated` now reports all
  direct/dev dependencies up-to-date.
- Removed the direct `flutter_local_notifications_linux` dependency: it is
  already pulled transitively by `flutter_local_notifications` and was never
  imported directly (verified with a repo-wide import search). It stays in the
  lockfile as a transitive dependency.
- No packages were added.

### Build size & release config (2.5)

- Android release already sets `isMinifyEnabled = true` and
  `isShrinkResources = true` with `proguard-android-optimize.txt` plus the
  project's `proguard-rules.pro`. No change was required; the rules keep the
  Flutter engine, the plugin entry points and the app's manifest-declared
  components, and suppress the unused Play Core split-install references.
- Documented the split-per-ABI and obfuscated AAB commands in the README.

### CI/CD (2.7)

- Added `.github/workflows/ci.yml` (there was only `release.yml`): format check,
  `flutter analyze --fatal-infos --fatal-warnings`, `flutter test --coverage`
  with a coverage artifact, and a debug-APK smoke build. Runs on pull requests
  and on pushes to non-`main` branches; `main` is owned by the existing release
  workflow.

### Repo hygiene (2.8)

- No secrets, keystores or API keys are tracked (`git ls-files` confirms; `*.jks`
  and `/dist/` are ignored). Local `dist/*.jks` and `keystore/*.jks` exist on
  disk only.
- `LICENSE` is Apache-2.0 and is consistent with the README.
- `android/app/src/main/res/xml/locales_config.xml` listed only `en`/`ar` while
  the app ships `fr`; added `<locale android:name="fr"/>` so French appears in
  Android 13+'s per-app language picker.

## Skipped or deferred

- **Major dependency upgrades.** None available for direct dependencies.
  Remaining outdated packages are transitive and held back by the Flutter SDK
  constraint (`dbus`, `xml`, `test_api`, `cli_util`, `gsettings`,
  `material_color_utilities`). Upgrading them means going off the SDK-pinned
  versions; not worth it here.
- **Splitting `lib/data/services/notification_service.dart` (~1,940 lines).**
  It is the largest file in the project and a good candidate for a
  responsibility split, but it is the highest-risk file (alarm/notification
  correctness) and a pure refactor with no behavior change cannot be validated
  by the current test suite on-device. Flagged for a dedicated, carefully
  verified PR rather than folded into this pass.
- **`dart:developer log` adoption.** `debugPrint` is used ~broadly; switching is
  cosmetic and would touch many files for no behavioral gain.
- **Arabic-Indic digits.** `intl` 0.20 renders generic `ar` with Latin digits;
  only `ar_EG` yields Arabic-Indic. Changing this is a user-visible decision for
  the maintainer (documented with a TODO in `test/time_formatter_test.dart`).
- **Android Gradle "Built-in Kotlin" migration.** A debug build emits a warning
  that `home_widget` and `workmanager_android` still apply the Kotlin Gradle
  Plugin, which a future Flutter version will reject. This is upstream in those
  plugins and can't be fixed here; watch for plugin releases that adopt
  Built-in Kotlin.

## Open TODOs and questions for the maintainer

- **`feat.md` is referenced but absent.** `docs/DECISIONS.md` and the old README
  cite a `feat.md` roadmap file that is not in the repo. Either add it or drop
  the references.
- **`update_manifest.json` is behind `pubspec.yaml`**: the manifest points at
  `0.12.1` while the app is `0.13.0`. This is expected between releases (the
  release workflow rewrites it), but flagging it so it is not mistaken for drift.
- **Screenshots**: none are committed. README carries a
  `<!-- TODO: add screenshots -->` placeholder; `docs/screenshots/` does not exist.
- **Security contact**: `SECURITY.md` uses a placeholder rather than a real
  private channel — fill it in.
- **`CODE_OF_CONDUCT.md` contact**: the enforcement contact is a TODO.
- **`stitch_minimal_prayer_times_app/`** is a tracked design-reference bundle
  (HTML/PNG/`DESIGN.md`). Left in place deliberately; decide whether it belongs
  in-repo or in a separate design repo.
- **`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`**, `SYSTEM_ALERT_WINDOW` and the
  `specialUse` foreground service still need their Play Console declarations
  (pre-existing; see the README release notes).

---

# Second pass — 2026-10-15

A follow-up run of the same brief on a tree where the first pass had already
landed and shipped as **0.13.1**. Everything the first pass added (strict lints,
CI, README/CHANGELOG/CONTRIBUTING and the community files) is present and in use,
so this pass deliberately avoided churn and targeted only the gaps that were
still open, all of them low-risk.

Environment: **Flutter 3.47.6 (stable)**, **Dart 3.13.5**.

## Baseline vs. after

| Check | Before | After |
| --- | --- | --- |
| `dart format --set-exit-if-changed .` | clean | clean |
| `flutter analyze` | 0 issues | 0 issues |
| `flutter test` | 164 passed | 182 passed |
| `flutter test --coverage` (line) | 37.0% | 37.4% |
| `flutter pub outdated` (direct + dev) | all up-to-date | all up-to-date |

The tree was already green at the start; no pre-existing failure had to be
repaired this time.

## What changed, by category

### Tests (2.6)

Three pieces of core policy had no automated coverage, and all three are pure
(no platform channels, no device):

- **`test/prayer_keys_test.dart`** — `PrayerKeys.id`/`fromId`,
  `occurrenceId`'s zero-padding, and `parseOccurrence`'s inverse/malformed-input
  behaviour. These strings are persisted by the scheduler, the mute list *and*
  the native side, so a rename is a data migration; the tests freeze the format
  and prove unknown ids are skipped rather than thrown on.
- **`test/muted_prayers_store_test.dart`** — mute round-trips, that unmuting
  removes only the targeted occurrence, and that unrelated preference keys are
  ignored. This is the store the lockscreen "Mute" action writes to directly.
- **`test/notification_policy_test.dart`** — the `adhanIsAudible` truth table
  (alarm off, `Silent` tone, device-tone override incl. the empty-URI fallback,
  stale tone names) and `prayerIdFor`'s delegation to the shared occurrence id.

Coverage of `lib/data/services/notification_service.dart` rises from 2.8% to
4.1%; `lib/core/const/prayer_keys.dart` and `lib/data/services/muted_prayers_store.dart`
go from 0% to 100%.

### CI/CD (2.7)

- `.github/workflows/ci.yml` now runs on **every push, including `main`**, not
  only pull requests and non-`main` branches. The release workflow still owns
  publishing; this only adds post-merge verification so a direct push cannot ship
  unchecked. (`main` was previously excluded by design; the brief asks for it.)

### Documentation

- `CONTRIBUTING.md` said adding a language needed "an entry in `l10n.yaml`'s
  supported locales". There is no such key — `flutter gen-l10n` infers the
  supported set from the ARB files in `arb-dir`. Corrected.
- `CHANGELOG.md` gained an `[Unreleased]` entry for this pass.

## Checked and left unchanged (already correct)

- **`const` / rebuild hygiene** — no raw `Opacity(`; the animated uses are
  `AnimatedOpacity`/`FadeTransition` (`floating_nav_bar`, `prayer_labels_header`,
  `segmented_control`). `RepaintBoundary` is used where the blur surface needs it.
- **Lazy lists** — the long, unbounded month list already uses
  `SliverList.builder`; the Home and Settings `ListView`s hold a short fixed
  child list. `GridView.count` is a fixed small month grid.
- **Controller disposal** — every `TextEditingController` and `Timer` in `lib/`
  is cancelled/disposed in a matching `dispose()`; the only `StreamController`s
  are the widget-tap stream (closed in a `finally`) and the notification
  service's app-lifetime broadcast controller.
- **No `print(`** anywhere in `lib/`; diagnostics already use `debugPrint`/`dart:developer`.
- **Release shrinking** — `isMinifyEnabled` + `isShrinkResources` with
  `proguard-android-optimize.txt` and the project rules are already on.

## Skipped or deferred (unchanged from the first pass, re-confirmed)

- **Splitting `lib/data/services/notification_service.dart` (~1,930 lines).** Still
  the largest file and still the highest-risk one — it is the alarm/notification
  core, and its coverage is single-digit even after this pass, so a pure refactor
  cannot be validated on-device by the current suite. Extracting its cohesive
  concerns (channels, permissions, ids, scheduling, playback, OTA) would touch the
  exact code paths the app exists to get right. This remains a dedicated,
  carefully device-tested PR rather than part of a docs/hardening pass.
- **Major dependency upgrades.** None are available for direct or dev
  dependencies; the remaining outdated packages are transitive and pinned by the
  Flutter SDK.
- **`home_widget_generator: any` in `pubspec.yaml`.** An `any` constraint is
  normally a smell, but here it deliberately tracks whatever version
  `home_widget_cli` resolves (both are at `0.4.0+1`) so the DSL schema and the
  generator that produced the checked-in widget code cannot drift. Left as is;
  flagged below in case the maintainer would rather pin it.
- **`dart:developer log` adoption**, **Arabic-Indic digits**, and the **Android
  Gradle "Built-in Kotlin" migration** — see the first pass; all still cosmetic or
  upstream.

## Open TODOs and questions for the maintainer

Carried over from the first pass and still true:

- **`feat.md` is referenced but absent.** `docs/DECISIONS.md` still cites it (the
  current README does not). `docs/DECISIONS.md` is also stale in places — it
  discusses the Qibla screen and `flutter_compass`, both removed in 0.12.1.
  Recommend either pruning it to the decisions that still apply or adding the
  missing `feat.md`. Not touched here (it predates this brief).
- **`update_manifest.json` is one release behind** `pubspec.yaml` (`0.13.0` vs
  `0.13.1`). Expected between releases — the release workflow rewrites and commits
  it — but noting it so it is not mistaken for drift.
- **Screenshots**: none committed; README still carries the
  `<!-- TODO: add screenshots -->` placeholder.
- **Security contact**: `SECURITY.md` and `CODE_OF_CONDUCT.md` still use TODO
  placeholders for a private contact — fill them in.
- **`stitch_minimal_prayer_times_app/`** design bundle: still tracked; decide
  whether it belongs in-repo.
- **Play Console declarations** for `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`,
  `SYSTEM_ALERT_WINDOW` and the `specialUse` foreground service remain outstanding.

