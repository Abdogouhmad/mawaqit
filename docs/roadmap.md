# Mawaqit Roadmap: 0.16.0 → 1.0.0

This is the working plan for the next several days of development. The target is
a **stable 1.0.0**: a calm, focused prayer-times app with a brand-new minimal
modern UI, a real feature set, and a release system that lets people choose
between **stable** and **beta** builds the way Keyel does.

Each row in the progress tracker is one version. Finish its **Definition of
done**, merge the phase branch to `main`, let CI cut the release, then move on.

> **Current state (baseline):** `0.15.2+1502`. The 0.15.x OTA/navigation work
> (fail-closed updater, global banner, launch notification, configurable checks,
> Material 3 bottom navigation) is on `main` and is the foundation this roadmap
> builds on. See [`CHANGELOG.md`](../CHANGELOG.md) Unreleased and
> [`production-readiness.md`](production-readiness.md).

**Current phase:** [`0.21.0 — Adhan 2.0`](roadmap_0.21.0.md).

---

## Rules for the whole project

1. **One phase = one branch.** Branch as `phase/0.16-channels`, merge only when
   the definition of done is met. Keep `main` releasable at all times.
2. **CI is the release manager.** Bump `pubspec.yaml` and add the matching
   `CHANGELOG.md` section, merge to `main`, and let `release.yml` build, sign,
   publish and rewrite the manifest. **Never push tags by hand.**
3. **CHANGELOG.md is the single source of truth** for user-facing notes. The
   release workflow extracts `## [<version>]` verbatim. No entry, no shipping.
4. **Versions increase with features, not with fixes.** Minor versions
   (`0.16.0`, `0.17.0`, …) are planned phases; patch versions are hotfixes cut
   from the phase branch when something escapes. `1.0.0` is a promise, not a
   date — it lands when the exit criteria below are met.
5. **OTA stays fail-closed.** HTTPS APK URL + strict 64-hex SHA-256 on every
   channel, stable and beta. No manifest may be offered, downloaded or
   installed without both. Beta is opt-in and never changes what stable users
   receive.
6. **Design tokens, not literals.** All new UI uses `AppTheme`, `AppColors`,
   `AppSpacing`, `AppRadius`, `AppMotion` / `AppSpring`. No hardcoded colours,
   sizes or durations.
7. **Every screen is RTL-correct, readable at 200 % text scale, and respects
   reduced motion / reduced transparency.** Tests must prove it, not eyeball it.
8. **EN / FR / AR parity.** Every new string goes into `app_en.arb` with a
   description and complete French and Arabic translations, then `flutter
   gen-l10n`. No hardcoded user-facing text.
9. **Risky logic gets tests before UI.** Alarm scheduling, notification policy,
   OTA integrity and channel resolution are tested first.
10. **Green before merge:** `dart format --set-exit-if-changed .`, `flutter
    analyze --fatal-infos --fatal-warnings`, `flutter test`, and a debug APK
    build. `docs/production-readiness.md` lists the device-only checks we must
    track separately.

---

## Release channels and versioning

### Version format

`pubspec.yaml` holds `X.Y.Z+B` where `B` is the derived Android version code
(`major*10000 + minor*100 + patch`, enforced by `build.sh`). One bump covers
app version, version code, tag, release and OTA manifest.

### Channels

The app ships two channels, mirroring Keyel:

| Channel | Manifest | Published by | Audience |
|---|---|---|---|
| **Stable** | `update_manifest.json` (committed at repo root) | CI on a version bump to `main` | Everyone by default |
| **Beta** | `update_manifest_beta.json` (committed at repo root) | Manual `workflow_dispatch` prerelease | Opt-in testers |

- `UpdateChannel` is an enum (`stable`, `beta`, defaults to `stable`). It is
  persisted as a lowercase string in `UpdateStore` (`update_channel`); any
  unknown/missing value falls back to `stable` (fail-closed).
- `UpdateService` fetches the manifest for the selected channel; a
  `customManifestUrl` override is kept for testing/dev.
- **Two separate committed manifests, not a query param and not a GitHub API
  call.** Stable → `update_manifest.json`, beta → `update_manifest_beta.json`,
  both served from `raw.githubusercontent.com` with a `?ts=<epoch ms>`
  cache-buster (the raw CDN can serve a stale copy for minutes after a
  release). This is exactly what Keyel does today.
- The beta manifest is seeded **empty** (`latestVersionName`/`apkUrl`/`sha256`
  blank) so no update is offered until the first beta dispatch rewrites it —
  fail-closed by construction.
- Manifests share one schema:
  `latestVersionName`, `latestVersionCode`, `minSupportedVersionCode`,
  `mandatory`, `releaseNotes`, `apkUrl`, `sha256`, `size`, `channel`,
  `isPrerelease`, `publishedAt`. `channel == 'beta'` marks a release as a
  prerelease even if `isPrerelease` is absent.
- Version comparison is semver-aware, including prerelease precedence:
  `1.9.0 > 1.9.0-beta.10 > 1.9.0-beta.2 > 1.9.0-beta.1`. The stable channel
  additionally filters out prereleases as a second gate, so a misconfigured
  stable manifest cannot ship a beta build.
- Switching channels persists the choice, clears the dismissed-version memory
  and stale release, and immediately re-checks. The previously installed APK
  is never silently downgraded.
- Beta prereleases keep the `beta` channel marker in the manifest and in the
  banner/notification copy (including a localized "(Beta)" suffix), so
  testers always know what they installed. A default-stable user sees nothing
  from the beta channel.

### Beta release procedure

1. Use the release workflow's `workflow_dispatch` with inputs:
   `channel=beta`, `beta_version` (e.g. `0.17.0-beta.1`), and `beta_notes`
   (markdown). A push to `main` **always** produces a stable release; beta is
   manual-only.
2. The beta job reuses the same signing key and build pipeline as stable, adds
   GitHub's `--prerelease` flag, uploads a distinct asset name, and rewrites
   **only** `update_manifest_beta.json` with the new version, release notes,
   size and SHA-256. The stable manifest is never touched.
3. The workflow re-downloads the published APK and verifies its SHA-256 against
   the manifest before committing the manifest back to `main`.
4. Stable users see nothing. Beta users get the banner + once-per-version
   notification. Promote to stable by merging the phase to `main` with the
   final version bump; CI cuts the stable release normally.

---

## The new UI: minimal modern

A single design language replaces the current mixed-density screens. The goal
is *calm, spacious, typographic and fast* — the design should get out of the
way of the prayer times.

**Principles**

- **Fewer surfaces.** One background, one card style, no nested containers,
  no decorative gradients. Elevation only where it communicates interaction.
- **Type does the work.** A clear type scale (Manrope + Arabic companion),
  generous line height, restrained weight contrast. Numbers — countdowns and
  times — are the visual heroes.
- **Rhythm and space.** A single spacing scale, consistent 8dp grid, large
  margins, readable tap targets. Content, not chrome, fills the screen.
- **One accent, semantic colours.** Theme palettes and AMOLED stay, but colour
  is used sparingly: accent for the next prayer, semantic colours for status.
- **Motion with meaning.** Short M3 transitions and existing `AppSpring`,
  disabled under reduced motion. No decoration for its own sake.
- **Direction-aware by default.** `EdgeInsetsDirectional`,
  `AlignmentDirectional`, mirrored icons; Arabic is a first-class layout, not
  a translation.

**Deliverables across the UI phases:** a token/component library, a new app
shell, redesigned Home, Times and Settings, a redesigned Update Center, an
onboarding/permissions flow, and a refreshed home-screen widget.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 0.16.0 | Release channels (stable/beta) + new Update Center | 2–3 days | ◐ |
| 0.17.0 | Design system 2.0 + app shell + navigation | 2–3 days | ☑ |
| 0.18.0 | New Home UI | 2–3 days | ☑ |
| 0.19.0 | New Times UI | 2 days | ☑ |
| 0.20.0 | New Settings, onboarding & permissions UI | 2–3 days | ☑ |
| 0.21.0 | Feature: Adhan 2.0 (tone preview, schedule control, reliability) | 3–4 days | ◐ |
| 0.22.0 | Feature: home-screen widget 2.0 & quick actions | 2–3 days | ☐ |
| 0.23.0 | Feature: Qibla direction & travel / multi-location mode | 3–4 days | ☐ |
| 0.24.0 | Feature: prayer insights & richer Hijri calendar | 2–3 days | ☐ |
| 0.25.0 | Accessibility, RTL & localization depth | 2 days | ☐ |
| 0.26.0 | Performance, reliability & test depth | 2–3 days | ☐ |
| 0.27.0 | Beta dogfooding & hardening | 3–5 days | ☐ |
| 1.0.0 | Stable release | 1–2 days | ☐ |

Legend: ☐ not started · ◐ in progress · ☑ done (code + verification).

Estimates assume focused part-time work. If a phase takes 2× the estimate, cut
scope, not quality.

> `docs/production-readiness.md` flags two standing questions to resolve before
> 1.0.0: (a) the in-app updater is incompatible with Google Play policy, so the
> distribution channel must be an explicit decision (GitHub sideloading today);
> (b) alarm/notification test depth is the risk to manage with on-device
> checklists.

---

## 0.16.0 — Release channels & the new Update Center

**Status:** code complete on `phase/0.16-channels`; awaiting merge/CI
verification of the beta `workflow_dispatch` path.

**Goal:** users can consciously choose stable or beta, understand the
difference, and see a redesigned, trustworthy Update Center. Full detail in
[`roadmap_0.16.0.md`](roadmap_0.16.0.md). The stable/beta release procedure and
the decisions behind the two manifests are recorded in
[`DECISIONS.md`](DECISIONS.md).

**Definition of done**

- Stable and beta channels are persisted, switchable and independently checked.
- Both manifests are fail-closed (HTTPS + valid SHA-256); beta cannot affect
  stable users.
- Beta workflow publishes a separate signed prerelease and manifest.
- Update Center is rebuilt in the new minimal style with channel choice,
  release notes, size, checksum/security explanation and install progress.
- Regression tests cover channel resolution, switch behaviour and integrity.

---

## 0.17.0 — Design system 2.0 + app shell

**Status:** code complete on `phase/0.17-design-system`; see
[`roadmap_0.17.0.md`](roadmap_0.17.0.md) for the phase detail.

**Goal:** establish the minimal modern language before restyling individual
screens, so every later phase reuses one set of tokens and components.

**Scope**

- Audit `lib/core/ui/theme/` and `lib/shared/ui/`: consolidate spacing, radii,
  typography, elevation, motion and colour into a documented token set.
- Build shared primitives: card, section header, list row, pill/badge, empty
  state, loading state, icon button, segmented control, action button.
- Rebuild `AppShell` / `NavigationBar` on those tokens; verify RTL and 200 %
  text at 360dp and 388dp.
- Delete dead widgets and duplicated layout code surfaced by the audit.

**Definition of done**

- No colour/size/duration literals in changed files; all from tokens.
- Component gallery or golden/widget tests cover every primitive at 1× and 2×
  text scale, LTR and RTL, light and dark.
- Existing tab layout tests still pass without overflow.

---

## 0.18.0 — New Home UI

**Status:** code complete on `phase/0.18-new-home-ui`; see
[`roadmap_0.18.0.md`](roadmap_0.18.0.md) for the phase detail.

**Goal:** a calm home surface where the next prayer and its countdown are the
hero, and everything else is supporting information.

**Scope**

- Rebuild `home_screen.dart` and its widgets (`countdown_hero`,
  `prayer_schedule_tile`, `solar_card`) on the new primitives.
- One clear focal card, a quiet prayer timeline, contextual Hijri/Gregorian
  date, and a direct path to Times and Settings.
- Keep the ticker narrow: only the countdown/next-prayer elements rebuild each
  second (preserve the 0.15.x optimisation).
- Preserve alarm reliability entry points and permission prompts.

**Definition of done**

- Home passes layout tests at 360/388dp, EN/FR/AR, 1.5×/2× text, dark/AMOLED.
- No whole-page rebuild on a clock tick (rebuild-counting test).
- Semantics labels for countdown, next prayer and actions.

---

## 0.19.0 — New Times UI

**Status:** code complete on `phase/0.19-new-times-ui`; see
[`roadmap_0.19.0.md`](roadmap_0.19.0.md) for the phase detail.

**Goal:** the monthly schedule becomes the clearest, fastest way to scan a
month and understand prayer-time shifts.

**Scope**

- Rebuild `times_screen.dart`, `prayer_grid`, `day_row`, `month_switcher`,
  `month_shift_card`, `almanac_header` on the new primitives.
- Calmer grid density, clearer selected/today states, legible shift indicators,
  direction-aware month paging.
- Keep cached Hijri conversions/formatters and the mid-page settings-change fix.

**Definition of done**

- No overflow at 360/388dp in any locale at 2× text.
- Month paging and settings-mid-page regression tests still pass.
- RTL month order and directional paging verified.

---

## 0.20.0 — New Settings, onboarding & permissions UI

**Status:** in progress on `phase/0.20-settings-onboarding-ui`; see
[`roadmap_0.20.0.md`](roadmap_0.20.0.md) for the phase detail.

**Goal:** a single, understandable place for every choice, plus a first-run
experience that explains the alarms instead of just asking for permissions.

**Scope**

- Rebuild `settings_screen.dart`, `screen/{general,notify,permission}.dart` and
  the widgets under `settings/widgets/` on the new primitives.
- Grouped sections with short explanations; every toggle says what it does.
- Onboarding/permissions flow that introduces notifications, exact alarms,
  full-screen access, DND and battery exemption in plain language, with live
  *Allowed / Fix* state and a path back to Settings.
- Wire the channel selector from 0.16.0 into the new settings information
  architecture.

**Definition of done**

- All existing preferences remain reachable; no setting silently disappears.
- Permission screen states round-trip through tests.
- Onboarding is skippable, resumable and localized in all three languages.

---

## 0.21.0 — Feature: Adhan 2.0

**Status:** in progress on `phase/0.21-adhan-2`; see
[`roadmap_0.21.0.md`](roadmap_0.21.0.md) for the phase detail.

**Goal:** make the app's signature feature easier to trust and customize.

**Scope**

- In-place tone preview with loudness/merge behaviour clearly explained.
- Per-prayer schedule controls (offsets, enable/disable, silent vs full adhan)
  with a readable weekly summary.
- Reliability dashboard: exact-alarm, overlay, DND and battery states with
  actionable *Fix* links.
- Keep the native alarm engine unchanged unless a test proves a defect.

**Definition of done**

- Tone/schedule preferences round-trip through `AppSettings` with tests.
- Notification policy tests cover every new combination.
- On-device smoke checklist for lockscreen takeover, silence and reschedule.

---

## 0.22.0 — Feature: widget 2.0 & quick actions

**Goal:** a home-screen widget that matches the new design and navigates
reliably.

**Scope**

- Redesign `prayer_widget` with the new type/spacing tokens; small and medium
  sizes, light/dark/AMOLED, Arabic layout.
- Quick actions (open Times, silence adhan) where platform APIs allow.
- Verify cold/warm launch routing and the no-flash behaviour.

**Definition of done**

- Widget generator output is consistent and widget tap routing tests pass.
- Widget previews cover both sizes and both locales.
- No blank/white launch frame on a light theme (existing guarded bootstrap).

---

## 0.23.0 — Feature: Qibla & travel mode

**Goal:** useful context beyond the home location.

**Scope**

- Qibla direction from the effective coordinates, with compass calibration
  guidance and an honest "sensor unavailable" state on desktop/test hosts.
- Travel / multi-location mode: temporary location with a clearly visible
  indicator and a one-tap return home; calculation method visible.
- Keep location permission opt-in and minimal; no background tracking.

**Definition of done**

- Bearing maths is unit-tested (including edge cases across the antimeridian).
- Travel state never silently overwrites the saved home location.
- No new broad permission; permission prompts remain explainable.

---

## 0.24.0 — Feature: prayer insights & richer Hijri calendar

**Goal:** give the calm UI something meaningful to show beyond "next prayer".

**Scope**

- Monthly prayer-time shift trends built on existing `TimesState.shifts`.
- Hijri calendar navigation with today/events emphasis and Gregorian mapping.
- Optional, local-only reminders/streaks — no account, no analytics, no sync.

**Definition of done**

- All computed insights are pure functions with tests.
- No network or device identifiers added; privacy note updated.
- Layout tests cover the new cards at 200 % text in all locales.

---

## 0.25.0 — Accessibility, RTL & localization depth

**Goal:** 1.0.0-quality inclusivity across every screen.

**Scope**

- Full semantics pass: every interactive element labelled, every image either
  meaningful or excluded, focus/traversal order correct in RTL.
- 200 % text and reduced-motion/transparency audits on every tab and dialog.
- ARB completeness audit: descriptions, plural forms where needed, no stale
  keys, EN/FR/AR parity verified by a test.
- Contrast audit against WCAG AA for all palettes, including AMOLED.

**Definition of done**

- Zero overflow/semantics exceptions in the widget test matrix.
- Localization parity test is green and enforced in CI.
- Contrast report committed under `docs/`.

---

## 0.26.0 — Performance, reliability & test depth

**Goal:** close the gap called out in `production-readiness.md`.

**Scope**

- Profile startup, tab switches and calendar paging; trim rebuilds and layout
  work. Keep the 0.15.x optimisations.
- Raise alarm/notification test coverage: scheduling, retry, cancellation,
  reschedule races and DND behaviour.
- Harden OTA: manifest validation matrix, channel switch during download,
  interrupted install recovery.
- Add on-device smoke checklists under `docs/testing.md` for the things CI
  cannot exercise.

**Definition of done**

- No regression in the existing 181+ tests; new tests cover the risky paths.
- Debug APK build and CI green with `--fatal-infos --fatal-warnings`.
- Device checklists exist and at least one full pass is recorded.

---

## 0.27.0 — Beta dogfooding & hardening

**Goal:** let the beta channel prove the new UI and features before stable.

**Scope**

- Publish at least one beta prerelease from the phase branch and update
  `update_manifest_beta.json` through the workflow, never by hand.
- Dogfood on real devices across locales, themes, text scales and Android
  versions; fix only what blocks 1.0.0.
- Final docs pass: README screenshots, `DECISIONS.md`, `production-readiness.md`,
  distribution decision, store/sideload copy.

**Definition of done**

- Beta users can discover, install and switch back to stable without data loss.
- No open blocker in `production-readiness.md`.
- Full verification matrix green.

---

## 1.0.0 — Stable release

**Goal:** declare stability and cut the release.

**Exit criteria**

- All phases above meet their definitions of done.
- CI and the release workflow are green; the stable manifest points at the
  signed 1.0.0 APK with a valid SHA-256.
- CHANGELOG has a complete `## [1.0.0]` section; README and docs match the
  shipped app.
- A documented on-device smoke pass covers: install/OTA, both channels,
  adhan on lockscreen, silence/reschedule, permissions, RTL, 200 % text,
  reduced motion, widget launch.
- Distribution choice is explicit and documented (GitHub sideload today;
  Play would require removing the in-app updater).

Tag and release are cut by CI from the version bump — never by hand.

---

## Reference

- Keyel's channel implementation (the model to follow):
  `keyel/lib/core/ota/{ota_models,ota_service,ota_provider}.dart`,
  `keyel/lib/data/app_preferences.dart`,
  `keyel/lib/features/ota/{ota_screen.dart,widgets/ota_screen_sections.dart}`,
  `keyel/update_manifest.json`, `keyel/update_manifest_beta.json`,
  `keyel/docs/DECISIONS.md`.
- Mawaqit's current OTA stack:
  `lib/data/models/update_manifest.dart`, `lib/data/services/update_service.dart`,
  `lib/features/settings/{update_store,update_controller}.dart`,
  `lib/core/ota/{update_check_host,update_available_banner}.dart`,
  `lib/features/settings/widgets/ota_update_screen.dart`,
  `update_manifest.json`.
- Release machinery: `.github/workflows/ci.yml`, `.github/workflows/release.yml`,
  `build.sh`, `pubspec.yaml`, `CHANGELOG.md`.
- Known constraints: [`production-readiness.md`](production-readiness.md),
  [`optimization-notes.md`](optimization-notes.md), [`testing.md`](testing.md),
  [`DECISIONS.md`](DECISIONS.md).
