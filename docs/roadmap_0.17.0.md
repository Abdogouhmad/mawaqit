# Mawaqit Roadmap: 0.17.0 — design system 2.0 & app shell

This phase establishes the minimal modern language on the road to
[`1.0.0`](roadmap.md) before the remaining screens are restyled. 0.16.0 shipped
the first screen in that style; 0.17.0 turns the one-off decisions into a
documented token set and shared primitives, then rebuilds the app shell on
them.

**Branch:** `phase/0.17-design-system`
**Version:** `0.17.0+1700` · **Est:** 2–3 days
**Status:** ☑ done (code + verification on `phase/0.17-design-system`)

Release stays CI-driven: bump `pubspec.yaml`, add the `## [0.17.0]` section to
`CHANGELOG.md`, merge to `main`, and let `release.yml` cut the tag and rewrite
`update_manifest.json`. **Never push tags by hand.**

---

## Goal

Every later phase should be able to restyle a screen by composing documented
tokens and shared widgets, not by copying spacing, colours, durations or a
navigation bar from the previous screen. The result is intentionally quiet:
warm paper surfaces, hairline structure, one emerald signal, and motion that
stops when the user asks for less. The full vocabulary lives in
[`design_system.md`](design_system.md).

---

## Rules for this phase

- One import: component code uses `core/ui/theme/app_tokens.dart`; raw values
  live only in the token files.
- Colour comes from the active `ColorScheme`; `AppOpacity` softens it. There is
  still no dynamic wallpaper colour.
- Selection uses `primaryContainer`/`onPrimaryContainer`, the pair already
  guarded by the palette contrast tests.
- Both motion families are respected: `AppMotion` for appearances, `AppSpring`
  for spatial movement and the reduce-motion signal.
- Support 360dp and 388dp, EN/FR/AR, LTR/RTL, 1x and 2x text, light and dark.
- When a pattern moves into a primitive, delete the local duplicate in the same
  commit. No parallel implementation survives this phase.

---

## Scope

### 1. Token consolidation

- [x] Add `app_tokens.dart` as the single import surface.
- [x] Add `effects.dart` for opacity, stroke, elevation, blur, component sizes,
      layout constraints, shapes, weights and typographic details.
- [x] Extend `motion.dart` with route/control/pulse durations and the soft curve;
      keep `AppMotion` for appearances and `AppSpring` for movement.
- [x] Add `AppColors.transparent` so even the absence of a tint is a token.
- [x] Document the vocabulary and review rules in `docs/design_system.md`.
- [x] Remove unused `Chip`, `Card` and `SegmentedButton` theme blocks.

### 2. Shared primitives

- [x] Keep the existing `AppCard`, `SectionHeader`, `AppPill`, `IconBadge`,
      `SegmentedControl`, `AppButton`, `EmptyState`, `InfoRow`, `SettingsRow` and
      `SettingsGroup`.
- [x] Add `AppListRow` as the generic leading/title/subtitle/trailing row.
- [x] Add `AppLoadingState` for in-place progress.
- [x] Add `AppIconButton` with standard/tonal/filled variants.
- [x] Add `AppNavigationBar` as the only bottom-navigation chrome.
- [x] Refactor `SettingsRow` onto `AppListRow`, removing its duplicate icon
      circle and haptic/tap logic.
- [x] Tokenize the existing primitives touched by this phase; no colour, size
      or duration literals remain in them.

### 3. App shell

- [x] Reduce `AppShell` to body selection + `AppChrome.constrain` +
      `AppNavigationBar`.
- [x] Use `primaryContainer`/`onPrimaryContainer` for the selected destination,
      aligned with the palette comments and contrast tests.
- [x] Keep localized labels, tooltips and tab order; the existing semantics and
      router tests still pass.
- [x] Remove the unused `AppChrome.screenPadding` helper.
- [x] Make `bottom_nav_test.dart` exercise the real shared bar, not a replica.

### 4. Accessibility and verification

- [x] Add `test/design_system_gallery_test.dart` covering every primitive at
      360/388dp, EN/AR, light/dark and 1x/2x.
- [x] Respect reduce-motion in `PulseDot`, `SegmentedControl` and
      `AppNavigationBar`; the platform setting and the in-app switch are OR-ed.
- [x] Run `dart format --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` (232
      passed) and a debug APK build on the phase branch.
- [x] Confirm the existing tab-layout and bottom-navigation suites still pass.

---

## Definition of done

- `docs/design_system.md` is the single reference for tokens and primitives.
- No raw colour, size or duration literals remain in the files changed here.
- The gallery covers every primitive at 1x/2x, LTR/RTL and light/dark.
- `AppShell` uses the shared navigation bar; no local duplicate remains.
- Existing tab-layout, bottom-navigation, palette and l10n tests are green.

---

## Deliberately out of scope

- Restyling individual feature screens: 0.18.0–0.26.0.
- A new font family or a dynamic wallpaper palette.
- Golden files: the bundled font/Flutter upgrade churn makes them brittle; the
  widget matrix above pins the same structural properties.
- More choice-tile primitives for settings: 0.20.0.
