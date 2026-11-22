# Mawaqit Roadmap: 0.18.0 — new Home UI

This phase turns the 0.17 token set into the first fully redesigned feature
screen. 0.16 rebuilt the Update Center in the new style, 0.17 documented the
language, and 0.18 applies it to the screen people open most: Home.

**Branch:** `phase/0.18-new-home-ui`
**Version:** `0.18.0+1800` · **Est:** 2–3 days
**Status:** ☑ done (code + verification on `phase/0.18-new-home-ui`)

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.18.0]` section to
`CHANGELOG.md`, merge to `main`, and let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

Home should read as one calm surface: a contextual date line, one focal card
with the next prayer and its countdown, a quiet five-row prayer timeline, a
compact solar summary, and a direct route to Times and Settings. No card
competes with the countdown; supporting information is typographic, tonal and
close to the content it explains.

The design keeps the same quiet-paper vocabulary as
[`design_system.md`](design_system.md): warm surfaces, hairline dividers, one
emerald signal, restrained weights and motion that stops under reduced motion.

---

## Composition

```
┌──────────────────────────────┐
│ Mawaqit          [cal] [set] │  header: one-line app actions
│   Sunday, 22 November 2026   │
│   ١جمادى الأولى ١٤٤٨ · Raleigh│  Gregorian + Hijri + location
│                              │
│  ┌────────────────────────┐  │
│  │ ● NEXT PRAYER          │  │
│  │     Dhuhr in 01:29:58  │  │  focal card: countdown is the hero
│  │ 12:15  [Fajr ended...] │  │
│  │ ────────────────       │  │
│  │ Fajr             5:10  │  │
│  └────────────────────────┘  │
│  DAILY SCHEDULE      North Am│
│  ┌────────────────────────┐  │
│  │  ●  Fajr         5:10  │  │
│  │  │  Dhuhr        12:15 │  │  timeline: rail + selected row
│  │  │  Asr           15:40│  │
│  │  │  Maghrib       18:05│  │
│  │  ○  Isha          20:10│  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ ☀ Solar Noon     12:30 │  │
│  │ 🌇 Sunset        18:05 │  │
│  └────────────────────────┘  │
│  NORTH AMERICA · SUNSET IN...│
│  🔒 Private & offline...     │
└──────────────────────────────┘
```

The dotted date meta replaces the previous eyebrow-heavy title block. The
timeline rail is the only structural ornament, and it encodes real sequence:
five prayers in order, with the active occurrence selected rather than merely
colour-tinted. Per-prayer mute controls remain separate semantics toggles.

---

## Scope

### 1. Home screen

- [x] Rebuild `home_screen.dart` on `AppCard`, `SectionHeader`,
      `AppIconButton`, `AppButton`, `EmptyState` and `UiText`.
- [x] Keep one `ListView` with direction-aware padding so Home scrolls and
      refreshes as before, but remove all one-off colour, size and weight
      literals.
- [x] Header gains direct, localized icon actions to Times and Settings;
      the location-missing indicator still opens Settings.
- [x] Contextual date line shows Gregorian date, Hijri date and location in
      one quiet two-line block.
- [x] `AlarmAccessGate` stays mounted once data resolves, so notification,
      exact-alarm, overlay and battery entry points are unchanged.
- [x] Debug-only full-screen adhan preview remains available behind
      `kDebugMode`.

### 2. Countdown hero

- [x] Rebuild `countdown_hero.dart` as the single focal `AppCard`.
- [x] Use the standard card surface; the primary countdown figures and a slim
      progress track are the only accents.
- [x] Replace raw paddings, radii, font weights, durations and curves with
      the 0.17 token vocabulary, adding only reusable `AppTypeDetail`/`AppSize`
      tokens where no token existed.
- [x] Keep the progress animation driven by `AppSpring.durationOf`, so reduce
      motion disables it.
- [x] Expose one merged semantics label for next prayer + countdown.

### 3. Prayer timeline and solar summary

- [x] Rebuild `prayer_schedule_tile.dart` as a row inside one shared card,
      with a leading rail, active `primaryContainer` selection and a separate
      mute toggle semantics node.
- [x] Rebuild `solar_card.dart` from two `AppListRow`s, removing its private
      two-column layout and duplicate divider geometry.
- [x] Preserve per-prayer mute state via `mutedPrayersProvider` and the same
      occurrence ids used by the native lockscreen card.
- [x] Keep tabular figures for times and countdowns.

### 4. Ticker boundary

- [x] `_LiveCountdown` and `_SunsetFooter` remain the only consumers of
      `homeClockProvider`.
- [x] A tick rebuilds those leaves only; the header, date line, prayer
      timeline, solar card and privacy note are untouched.
- [x] `HomeState` remains the data boundary; no logic moved into widgets.

### 5. Accessibility and verification

- [x] New `test/home_layout_test.dart` sweeps 360/388dp, EN/FR/AR, 1×/1.5×/2×
      text and light/dark/AMOLED with a real current/next prayer pair.
- [x] Semantics test covers the hero, Times/Settings actions and mute toggles.
- [x] Rebuild-counting test proves a clock tick does not rebuild `HomeScreen`.
- [x] Run `dart format --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` and a
      debug APK build on the phase branch.
- [x] Existing tab-layout, bottom-navigation and design-system suites still
      pass.

---

## Definition of done

- Home passes layout tests at 360/388dp, EN/FR/AR, 1.5×/2× text, dark/AMOLED.
- No whole-page rebuild on a clock tick (rebuild-counting test).
- Semantics labels exist for countdown, next prayer and actions.
- Alarm reliability entry points and permission prompts are unchanged.
- No raw colour, size or duration literals remain in the changed UI files.

---

## Deliberately out of scope

- Times, Settings, onboarding and home-screen widget redesigns: later phases.
- New ARB strings: the new layout reuses the existing localized vocabulary.
- Alarm engine or notification policy changes: behaviour is preserved exactly.
- Golden files: the widget-matrix approach from 0.17 remains the contract.
