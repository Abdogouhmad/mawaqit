# Mawaqit Roadmap: 0.16.0 — release channels & the new Update Center

This is the first phase on the road to [`1.0.0`](roadmap.md). It turns the
single-channel updater shipped in 0.15.x into a two-channel system (stable and
beta, like Keyel) and gives it the first screen rebuilt in the minimal modern
style that later phases will standardise.

**Branch:** `phase/0.16-channels`
**Version:** `0.16.0+1600` · **Est:** 2–3 days
**Status:** ☐ not started

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.16.0]` section to
`CHANGELOG.md`, merge to `main`, let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

A user can open *Software Update*, see a clear explanation of stable vs beta,
switch channels, and immediately see the releases available on that channel.
Beta builds are signed GitHub **prereleases** with their own SHA-256-verified
manifest; opting in never changes what stable users receive. The screen itself
is the first expression of the new minimal UI language.

---

## Rules for this phase

- Both channels are **fail-closed**: absolute HTTPS APK URL + a strict 64-hex
  SHA-256, verified natively before install. No exceptions for beta.
- The stable manifest is never written by a beta workflow, and a beta build is
  never marked as `latest` on GitHub.
- Channel state is opt-in, persisted, and never silently migrates a user.
- Every new string lands in all three ARBs (`app_en`, `app_fr`, `app_ar`) with
  a description, then `flutter gen-l10n`.
- UI changes use existing tokens (`AppTheme`, `AppColors`, `AppSpacing`,
  `AppRadius`, `AppMotion`) only. This phase *uses* the design system; defining
  version 2 of it is 0.17.0.
- The screen must be readable at 200 % text scale, RTL-correct, and pass the
  existing widget-test matrix with no new overflow.

---

## Knowledge

**Mawaqit today (paths and symbols):**

- `lib/data/models/update_manifest.dart` — `UpdateManifest`,
  `isValidUpdateChecksum`, `isSecureUpdateUrl`, `isInstallable`. Already
  validates HTTPS + 64-hex SHA-256.
- `lib/data/services/update_service.dart` — `UpdateService.fetchManifest()`,
  `check()`, `downloadAndInstall()`; `kUpdateManifestUrl`, `kGitHubRepo`.
- `lib/features/settings/update_store.dart` — `UpdateStore` (SharedPreferences
  keys for last check/result, notified version, dismissed version, auto-check,
  notification prompt).
- `lib/features/settings/update_controller.dart` — `UpdateState`,
  `UpdateNotifier`, `checkForUpdates()`, `_notifyIfNew()`, `setAutoCheck()`,
  `dismissUpdateBanner()`, `downloadAndInstall()`.
- `lib/core/ota/update_check_host.dart` — foreground checks on mount/resume/
  30-min timer; `lib/core/ota/update_available_banner.dart` — global banner.
- `lib/features/settings/widgets/ota_update_screen.dart` — the current Update
  Center (status header, version card, changelog, install action, preferences
  card).
- `update_manifest.json` — the committed stable manifest; the CI workflow
  rewrites it on a version bump.

**Keyel's reference implementation (read before designing):**

- `keyel/lib/core/ota/ota_models.dart` — channel enum/model and manifest fields.
- `keyel/lib/core/ota/ota_service.dart` — channel-aware manifest fetching:
  **two separate committed manifests** with `?ts=` cache busting for both
  channels (no GitHub API call), plus a `customManifestUrl` override. Note
  Keyel's `docs/DECISIONS.md` has a stale note claiming beta uses the Releases
  API — trust the code and the newer decision at the end of that file.
- `keyel/lib/core/ota/ota_provider.dart` — channel state and switching logic.
- `keyel/lib/data/app_preferences.dart` — persisted `otaChannel`.
- `keyel/lib/features/ota/ota_screen.dart` and
  `keyel/lib/features/ota/widgets/ota_screen_sections.dart` — channel picker and
  update UI/copy.
- `keyel/update_manifest.json` and `keyel/update_manifest_beta.json` — the two
  committed manifests.
- `keyel/docs/DECISIONS.md` — why stable uses the raw manifest and beta uses
  the Releases API, and how beta releases are published.

---

## Todo

### 1. Channel model and persistence

1. [ ] Add an `UpdateChannel` enum (`stable`, `beta`) in
       `lib/data/models/` (or alongside `UpdateManifest`, matching existing
       conventions). Include a display label/backing key.
2. [ ] Extend `UpdateManifest` with the channel fields it does not already
       carry (`channel`, `isPrerelease`) and pin them in `fromJson` tests.
       `size` and `publishedAt` already exist.
3. [ ] Add `update_channel` to `UpdateStore` with a default of `stable`, plus
       `channel()` / `saveChannel()` and a test that a missing key stays stable.
4. [ ] Hydrate the channel in `UpdateNotifier.hydrate()` and expose it on
       `UpdateState` so the UI and check host can react to it.

### 2. Channel-aware fetching and checks

5. [ ] Add a channel-aware manifest URL builder to `UpdateService`: stable →
       `kUpdateManifestUrl`, beta → a new `kUpdateManifestBetaUrl` pointing at
       `update_manifest_beta.json`, both with the existing `?ts=` cache bust.
6. [ ] Add an optional `customManifestUrl` override for local testing/dev,
       mirroring Keyel.
7. [ ] Make `fetchManifest()` take the selected channel (read from state or an
       explicit argument), keeping the fail-closed `tryDecode` path unchanged.
8. [ ] Add a `setChannel()` notifier action that persists the choice, clears
       stale banner/check state, and triggers an immediate silent re-check.
       Never downgrade silently; surface "installed build is newer than this
       channel" as up-to-date with a short explanation.
9. [ ] Use semver-aware version comparison with prerelease precedence, and
       filter prereleases out of the stable channel as a second gate so a
       misconfigured stable manifest cannot ship a beta build.
10. [ ] Include the channel in the banner/notification copy for beta (with a
        localized "(Beta)" suffix) so testers always know what they installed;
        default-stable users see nothing from beta. Keep `UpdateCheckHost`
        behaviour identical: same throttle, same foreground-only promise, no
        background service.

### 3. Beta manifest and release workflow

11. [ ] Create `update_manifest_beta.json` at the repo root **seeded empty and
        fail-closed** (blank `latestVersionName`/`apkUrl`/`sha256`, `size: 0`,
        `"channel": "beta"`, `"isPrerelease": true`) so no beta update is
        offered until the first dispatch publishes one.
12. [ ] Extend `.github/workflows/release.yml` with `workflow_dispatch` inputs
        `channel` (`stable`/`beta`), `beta_version` (e.g. `0.17.0-beta.1`) and
        `beta_notes` (markdown). A push to `main` always publishes stable; beta
        is manual-only. Beta reuses the same signing key and build pipeline,
        publishes a GitHub **prerelease** (`--prerelease`, never `latest`) with
        a distinct asset name, and rewrites only `update_manifest_beta.json`
        with version, notes, size and SHA-256.
13. [ ] Guard the workflow so a beta run can never touch `update_manifest.json`
        or the `latest` release, and a stable run can never touch the beta
        manifest. Re-download the published APK and verify its SHA-256 against
        the manifest before committing that channel's manifest back to `main`.
14. [ ] Document the beta release procedure in `docs/DECISIONS.md` and link it
        from `docs/roadmap.md`.
15. [ ] Verify the workflow with a dry-run/dispatch on the phase branch before
        merging; confirm the stable manifest checksum is unchanged.

### 4. New Update Center UI (first minimal-modern screen)

16. [ ] Rebuild `ota_update_screen.dart` on shared tokens with a clear
        hierarchy: channel selector at the top, current-vs-available version,
        release notes, size/checksum/security note, primary install action,
        quiet preferences card at the bottom.
17. [ ] Add a self-explaining channel picker (radio cards, not an unlabelled
        segmented control): *Stable — verified releases everyone receives* and
        *Beta — early builds, may be less stable*. Show the active channel.
18. [ ] Show each release's source badge (`Stable`/`Beta`) and `publishedAt`
        where the manifest provides it; show `formattedSize` before download.
19. [ ] Replace raw error codes with calm, localized explanations and a single
        retry action; keep the checksum/HTTPS explanation visible.
20. [ ] Preserve existing behaviours: once-per-version notification, dismissible
        banner, auto-check toggle, notification opt-in, mandatory updates.
21. [ ] Add all new strings to the three ARBs with descriptions; regenerate
        localizations.

### 5. Tests and verification

22. [ ] Unit-test channel resolution, URL building, cache-busting, switch
        behaviour, semver prerelease ordering, stable-channel prerelease
        filtering, and that both channels enforce HTTPS + SHA-256.
23. [ ] Widget-test the channel picker: switching calls the notifier, the
        badge updates, and the screen stays within 360/388dp at 2× text in
        EN/FR/AR, LTR/RTL.
24. [ ] Verify the empty beta seed offers no update, a populated beta manifest
        parses and installs with its SHA-256, and a malformed beta manifest is
        treated as `checkFailed`. Confirm the stable manifest checksum is
        unchanged by a beta dispatch.
25. [ ] Run the full matrix: format, `analyze --fatal-infos --fatal-warnings`,
        `flutter test`, debug APK build; record results in the phase PR.
26. [ ] Add a `## [0.16.0]` CHANGELOG section covering the user-visible channel
        and UI changes, then bump `pubspec.yaml` to `0.16.0+1600`.

---

## Definition of done

- [ ] Stable and beta channels are persisted, switchable, and independently
      re-checked; beta opt-in does not alter stable users' updates.
- [ ] Both channels fetch distinct committed manifests over HTTPS with cache
      busting; both fail closed on a missing/malformed SHA-256.
- [ ] A beta `workflow_dispatch` release produces a signed prerelease and
      updates only `update_manifest_beta.json`.
- [ ] The redesigned Update Center passes layout/semantics tests in all three
      languages at 200 % text, LTR and RTL, light and dark.
- [ ] All new strings are translated; no hardcoded user-facing text.
- [ ] Full verification matrix is green and recorded.
- [ ] `CHANGELOG.md` and `pubspec.yaml` are bumped; CI cuts `v0.16.0` on merge.

---

## Out of scope for this phase

- Redefining the design tokens or rebuilding other screens (0.17.0–0.20.0).
- New prayer-time features (0.21.0+).
- Google Play distribution changes; the in-app updater stays and the
  distribution decision remains tracked in `production-readiness.md`.
