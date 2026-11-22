# Mawaqit Roadmap: 0.20.0 — new Settings, onboarding & permissions UI

This phase finishes the redesign of the app's three primary surfaces. 0.18
rebuilt Home, 0.19 rebuilt Times, and 0.20 gives every preference one calm home
and replaces the first-run permission gate with a short explanation of *why* the
app needs each access.

**Branch:** `phase/0.20-settings-onboarding-ui`
**Version:** `0.20.0+2000` · **Est:** 2–3 days
**Status:** ◐ in progress on `phase/0.20-settings-onboarding-ui`

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.20.0]` section to
`CHANGELOG.md`, merge to `main`, and let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

Settings should be a single, scannable column: each section says what it
controls, each toggle says what it does, and nothing is hidden three taps deep.
The update-channel choice from 0.16 becomes an ordinary, clearly explained
preference instead of a separate screen. Onboarding introduces alarms in the
same voice: one idea per page, plain-language permission explanations, live
*Allowed / Fix* state, and a path back to Settings at every step.

---

## Scope

### 1. Settings surface

- [ ] Rebuild `settings_screen.dart` and `screen/{general,notify,permission}.dart`
      on `AppCard`, `AppButton`, `AppPill`, `UiText` and the token façade.
- [ ] Group related preferences with one-line explanations; every toggle labels
      its effect rather than just its name.
- [ ] Keep every existing preference reachable — no setting silently disappears.
- [ ] Wire the 0.16 stable/beta channel selector into the grouped information
      architecture without changing the fail-closed update contract.

### 2. Onboarding and permissions

- [ ] Explain notifications, exact alarms, full-screen access, DND and battery
      exemption in plain language before asking for each one.
- [ ] Show live *Allowed / Fix* state for every permission and a direct route to
      the relevant system setting or back to Settings.
- [ ] Keep onboarding skippable and resumable; persist the same flag so returning
      users never see it again.
- [ ] All three locales (EN/FR/AR) at parity, including RTL flow.

### 3. Behavior preservation

- [ ] No change to the native alarm engine, notification policy or OTA checks.
- [ ] Preference round-trips and controller/provider behavior are unchanged.

### 4. Accessibility and verification

- [ ] Widget tests cover every permission state and the skip/resume path.
- [ ] Layout tests at 360/388dp, EN/FR/AR, 1×/1.5×/2× text, light/dark/AMOLED.
- [ ] Run `dart format --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` and a
      debug APK build on the phase branch.

---

## Definition of done

- All existing preferences remain reachable; no setting silently disappears.
- Permission screen states round-trip through tests.
- Onboarding is skippable, resumable and localized in all three languages.
- No raw colour, size or duration literals remain in the changed UI files.
- No overflow at 360/388dp in any locale at 2× text.

---

## Deliberately out of scope

- Adhan tone preview, per-prayer schedules and the reliability dashboard: 0.21.
- Home-screen widget and quick actions: 0.22.
- New calculation logic, native alarm changes or OTA behavior: unchanged.
