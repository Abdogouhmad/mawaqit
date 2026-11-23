# Mawaqit Roadmap: 0.21.0 — Adhan 2.0

The redesign is done: 0.18 rebuilt Home, 0.19 rebuilt Times and 0.20 rebuilt
Settings with onboarding. 0.21 turns to the app's signature feature and makes
the adhan easier to trust and customize — without touching the native alarm
engine unless a test proves a defect.

**Branch:** `phase/0.21-adhan-2`
**Version:** `0.21.0+2100` · **Est:** 3–4 days
**Status:** ◐ in progress on `phase/0.21-adhan-2`

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.21.0]` section to
`CHANGELOG.md`, merge to `main`, and let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

Three questions, answered in the app before the user has to ask:

1. *What will I hear, and how loud?* — preview the chosen adhan and reminder
   tones in place, with plain-language loudness and merge behaviour.
2. *When will each prayer ring, and how?* — per-prayer offsets, enable/disable
   and silent/full choice, summarized for the whole week.
3. *Will it actually ring?* — a reliability dashboard that shows the live
   exact-alarm, overlay, DND and battery states with an actionable *Fix* link.

---

## Scope

### 1. Tone preview

- [ ] Preview the selected adhan and pre-prayer reminder tones in place, from
      the notifications screen, without leaving Settings.
- [ ] Explain merge behaviour (what plays over what) and loudness in one line
      each, in all three locales.
- [ ] Reuse the 0.17 tokens; no raw colour, size or duration literals.

### 2. Per-prayer schedule controls

- [ ] Per-prayer enable/disable, minute offset and silent/full adhan choice,
      persisted in `AppSettings` and round-tripped through tests.
- [ ] A readable weekly summary of the resulting schedule.
- [ ] Keep the existing global reminder behaviour as the safe default; no
      silent regression for users who never open the new controls.

### 3. Reliability dashboard

- [ ] Show live exact-alarm, overlay, notification-policy (DND) and battery
      states with a *Fix* link to the matching Android screen.
- [ ] Reuse the 0.20 permission model and the *Allowed / Fix* vocabulary; keep
      the dashboard read-only except for the system-setting links.

### 4. Behavior preservation and verification

- [ ] Native alarm engine, notification policy and OTA checks unchanged unless
      a test proves a defect.
- [ ] Unit tests cover every new preference round-trip and notification-policy
      combination; widget tests cover the new screens and states.
- [ ] Layout tests at 360/388dp, EN/FR/AR, 1×/1.5×/2× text, light/dark/AMOLED.
- [ ] Run `dart format --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` and a
      debug APK build on the phase branch.

---

## Definition of done

- Tone and schedule preferences round-trip through `AppSettings` with tests.
- Notification-policy tests cover every new combination.
- On-device smoke checklist for lockscreen takeover, silence and reschedule is
  documented (the automated suite covers the Dart-side state).
- No raw colour, size or duration literals remain in the changed UI files.
- No overflow at 360/388dp in any locale at 2× text.

---

## Deliberately out of scope

- Home-screen widget and quick actions: 0.22.
- Qibla direction and travel / multi-location mode: 0.23.
- New calculation logic, native alarm changes or OTA behavior: unchanged.
