# Mawaqit Roadmap: 0.19.0 — new Times UI

This phase applies the 0.17 token vocabulary to the screen built for precision:
the monthly prayer schedule. 0.18 gave Home a single focal card; 0.19 makes the
month legible without turning thirty-one days into a wall of shrunken numbers.

**Branch:** `phase/0.19-new-times-ui`
**Version:** `0.19.0+1900` · **Est:** 2 days
**Status:** ☑ done (code + verification on `phase/0.19-new-times-ui`)

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.19.0]` section to
`CHANGELOG.md`, merge to `main`, and let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

The Times tab should answer two questions at a glance: *what time is it on this
day* and *is the month moving earlier or later*. The day list owns the first
question with aligned, full-size columns; one quiet shift card owns the second.
The masthead names the month, the Hijri span and the location once, and pages in
the reading direction.

---

## Composition

```
┌──────────────────────────────┐
│ 📍 Raleigh, NC        [Today]│  location, shortcut only when paged away
│      ‹   November 2026   ›   │  month is the picker control
│       Jumada I – Jumada II   │
│  ┌────────────────────────┐  │
│  │ ● TODAY   ١٤٤٨ · 22 Nov│  │
│  │       ╭────☀────╮      │  │  solar arc, sunrise/sunset anchors
│  └────────────────────────┘  │
│  THE MONTH AT A GLANCE       │
│  Fajr ↑12m   Dhuhr ↓8m  …    │  one card: direction + magnitude
│  ─────── prayer labels ───── │  pinned above the month
│  22 Sat 1448  5:10  6:00 …   │  today row: one filled treatment
│  23 Sun 1448  5:11  6:01 …   │  quiet rows: no clock-based dimming
└──────────────────────────────┘
```

The grid still resolves its column count once per month from the strings it will
actually draw, so every row and the pinned header stay aligned. What changed is
the surface language: one ink role for today, one accent for the next prayer,
and the solar tertiary only for astronomical facts.

---

## Scope

### 1. Month masthead and picker

- [x] Rebuild `almanac_header.dart` from `AppIconButton`, `AppPill`, `UiText`
      and the token façade: location eyebrow, month as the picker control,
      Hijri span, today shortcut.
- [x] Rebuild `month_switcher.dart` as a twelve-month `GridView` whose cells are
      `AppPill`s with distinct selected/current/disabled treatments.
- [x] Paging chevrons and picker grid follow `Directionality`; the same
      `TimesState` bounds gate both controls and the controller.
- [x] The sheet scrolls instead of clipping at 200% text or on short screens.

### 2. Month summary and solar context

- [x] Rebuild `month_shift_card.dart` on `AppCard`, using tabular figures and a
      localized icon + direction for each prayer's signed drift.
- [x] Rebuild `solar_arc.dart` as one token-sized hairline arc with a soft sun
      halo; keep sunrise/sunset anchors and the localized solar-noon caption.
- [x] Keep `TimesState.shifts` memoised and suppress the whole card when a shift
      is not plausible.

### 3. Day rows and grid

- [x] Rebuild `day_row.dart` with one filled today treatment, a hairline weekday
      accent and explicit passed/next-prayer ink.
- [x] Tokenize `prayer_grid.dart` and `prayer_labels_header.dart` so measured
      geometry and pinned-header extent still agree.
- [x] Preserve the single `PrayerGrid` resolved per month and the shared
      `_widestText` cache; no per-row measuring was introduced.

### 4. Behavior preservation

- [x] `TimesController` still reuses Home's resolved coordinates, pages without
      a full-screen spinner and ignores appearance-only settings changes.
- [x] The mid-page settings recompute keeps the selected month when a slower
      calculation finishes.
- [x] Hijri conversion/format caching and 12/24-hour formatter behavior are
      unchanged.

### 5. Accessibility and verification

- [x] New `test/times_ui_test.dart` sweeps 360/388dp, EN/FR/AR, 1×/1.5×/2×
      text and light/dark/AMOLED.
- [x] Semantics test covers paging controls, month selection, today state,
      shift card cells and their directions.
- [x] RTL test proves the chevrons swap and the month grid places January on
      the reading-start edge.
- [x] Controller tests cover one-month paging, bound rejection and a
      times-setting change while a paged month is on screen.
- [x] `test/tab_layout_test.dart` and `test/times_state_test.dart` still pass.
- [x] Run `dart format --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` and a
      debug APK build on the phase branch.

---

## Definition of done

- No overflow at 360/388dp in any locale at 2× text.
- Month paging and settings-mid-page regression tests pass.
- RTL month order and directional paging are verified.
- No raw colour, size or duration literals remain in the changed UI files.
- No new ARB strings: the rebuilt UI reuses the existing localized vocabulary.

---

## Deliberately out of scope

- Settings, onboarding and permission UI: 0.20.
- Adhan scheduling, notification policy or OTA behavior: unchanged.
- New prayer-time calculation logic: the controller and service are preserved.
- Golden files: the widget-matrix tests remain the visual contract.
