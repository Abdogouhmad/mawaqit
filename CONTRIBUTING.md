# Contributing to Mawaqit

Thanks for your interest in improving Mawaqit. This guide covers what the
project is, how it is built, and how to get a change merged.

## What this project is

Mawaqit is a calm, focused **prayer-times app for Android** (with a Linux desktop
target used for development). Its goal is an adhan that reliably rings like a
real alarm clock — including on the lockscreen and with the app closed — while
keeping the interface quiet and readable.

**In scope:** accurate prayer times, reliable alarms/notifications, the
home-screen and lockscreen cards, localization (English, Arabic, French), OTA
updates, and privacy (all computation on-device).

**Out of scope (for now):** iOS/web/desktop as shipping targets, accounts or any
cloud sync, analytics/tracking, and the Qibla screen (removed pending a rewrite
— see `CHANGELOG.md`).

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By
participating you agree to uphold it. Report unacceptable behavior to the
maintainer (see the contact in that file).

## Ways to contribute

- **Bug reports** — use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).
- **Feature requests** — use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).
- **Code** — bug fixes, performance work, and features that fit the scope above.
- **Translations** — the app ships English, Arabic and French. ARB catalogs live
  in `lib/l10n/` (`app_en.arb`, `app_ar.arb`, `app_fr.arb`); adding a locale means
  a new ARB file (there is no `supported-locales` list in `l10n.yaml` — `gen-l10n`
  infers the supported set from the ARB files present) and an entry in
  `android/app/src/main/res/xml/locales_config.xml` so it appears in Android
  13+'s per-app language picker.
- **Testing** — trying builds on real devices (OEM Android is where alarm
  behavior varies) and reporting what you find is genuinely useful.
- **Docs** — corrections and clarifications are welcome.

## Development setup

1. Install Flutter **3.47.x** (stable channel; Dart **3.13+**). Run
   `flutter doctor -v` and resolve anything it flags.
2. Fork and clone:

   ```sh
   git clone git@github.com:<your-username>/mawaqit.git
   cd mawaqit
   ```

3. Install dependencies (this also runs localization codegen):

   ```sh
   flutter pub get
   ```

4. Run it. On Android, use a device/emulator; for quick iteration you can use the
   Linux target:

   ```sh
   flutter run          # or: just run
   just run-linux       # flutter run -d linux
   ```

5. Optional tooling: [`just`](https://github.com/casey/just) (task runner) and
   Python 3 (tone generation). After editing the widget schema, regenerate with
   `just widget`.

No environment files or local secrets are needed to build and test. Release
signing is handled entirely by `build.sh` and the release workflow.

## Architecture and conventions

- **Layers.** UI lives in `features/<area>/` as small widgets; state is exposed
  through Riverpod providers in `providers/providers.dart` and
  `*_controller.dart`; the data layer is `data/repositories` +
  `data/services`; shared design-system widgets are in `shared/` and `core/ui/`.
  Keep the dependency direction pointing *downward* (UI → state → data).
- **State management is Riverpod 3** — extend the existing providers rather than
  introducing another state solution.
- **Design system.** Use the tokens in `core/ui/theme/` and the shared widgets in
  `shared/` (`AppButton`, `AppCard`, `UiText`, …) instead of raw Material styling
  or hard-coded colors, spacing and radii. Avoid magic numbers.
- **Localization.** Never hard-code user-facing strings. Add keys to the ARB
  files and read them via `AppLocalizations.of(context)`. Because `l10n.yaml`
  sets `nullable-getter: false`, every widget that shows text must be pumped with
  the delegates in widget tests.
- **Naming.** Files and directories use `snake_case`; classes use `UpperCamelCase`;
  private members are prefixed with `_`; providers end in `Provider`.
- **Native Android** lives in
  `android/app/src/main/kotlin/com/freesoftware/mawaqit/`. Keep the Flutter and
  native sides in step (channel names are centralized in `core/const/channel_names.dart`).

## Branching and commits

- Branch from `main`, named by intent: `feat/…`, `fix/…`, `docs/…`, `ci/…`,
  `refactor/…`, `chore/…` (e.g. `fix/solar-card-overflow`).
- Use **Conventional Commits**:

  ```
  feat(times): add a month-at-a-glance card
  fix(home): wrap text rows so they can't overflow
  docs(readme): document the Linux dev target
  test(update): cover the update-decision matrix
  ```

  Keep commits small and focused; use the scope that matches the area you touched.

## Coding standards

- `dart format .` — code must be formatted.
- `flutter analyze` — must be **clean**. The rules in `analysis_options.yaml`
  (const/immutability, `unawaited_futures`, `use_build_context_synchronously`,
  etc.) are enforced; do not silence a lint with `// ignore:` unless there is a
  documented reason.
- Prefer `const` constructors and widgets; split large `build` methods into
  separate widget classes (not helper methods); dispose controllers, streams,
  timers and focus nodes.
- Add `///` doc comments to public APIs and non-obvious logic.

## Testing requirements

- Every bug fix should come with a regression test; new logic should have unit
  tests. UI changes should be exercised by a widget test where practical (the
  layout suite in `test/tab_layout_test.dart` sweeps widths, locales and text
  scales — extend it when you touch layout).
- Run the full suite before opening a PR:

  ```sh
  flutter analyze
  dart format --output=none --set-exit-if-changed lib test
  flutter test
  flutter test --coverage   # optional; writes coverage/lcov.info
  ```

## Pull request process

1. Keep the PR focused on one change; describe **what** and **why**, and link any
   related issue.
2. Make sure the checklist in the [PR template](.github/PULL_REQUEST_TEMPLATE.md)
   is satisfied: tests pass, analyzer is clean, docs/CHANGELOG updated, and
   screenshots attached for UI changes.
3. Update `CHANGELOG.md` under `## [Unreleased]` for any user-visible change.
4. A maintainer will review. Response times depend on availability — a polite
   ping after a week is fine. Please don't force-push over review comments;
   add commits and let the maintainer decide when to squash.

## Reporting bugs

Please include:

- Output of `flutter doctor -v`.
- Device model and Android version (or "Linux desktop").
- Clear steps to reproduce, expected vs. actual behavior.
- Logs: `flutter run` console output, and `adb logcat` for native/alarm issues.
- Screenshots or a screen recording for UI problems.

## Requesting features

Open a feature request describing the problem you want solved and the behavior
you'd like. For anything non-trivial, discuss it in the issue before writing
code so we agree on the approach — this is especially important for changes to
the alarm/notification pipeline, which is the app's core.

## Security

Please do not report security vulnerabilities in public issues. See
[SECURITY.md](SECURITY.md) for how to report them privately.

## License

By contributing, you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE), the same license as the project.
