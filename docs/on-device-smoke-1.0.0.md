# 1.0.0 beta — on-device smoke pass

This is the recorded result of the manual matrix in [`testing.md`](testing.md)
(sections 1–11), run against the `1.0.0-beta.1` prerelease. Fill it in on a
physical device before the stable build is declared; CI cannot exercise
sensors, the installer, or the lockscreen.

**Release plan:** 1.0.0 ships to the beta channel first. Once every row below
is a pass (or an agreed, documented non-blocker), the same feature set is
bumped to `1.0.1` and released as stable from `main`. The stable manifest and
`main` are deliberately left on `0.21.0` until that sign-off.

| Field | Value |
| --- | --- |
| Device / Android version | _pending_ |
| Build (APK SHA-256 or tag) | _pending_ |
| Tester | _pending_ |
| Date | _pending_ |
| Locales tested | en / fr / ar |
| Themes tested | light / dark / AMOLED |

## Result

| Section | Result | Notes |
| --- | --- | --- |
| 1–5. Alarm core (existing matrix) | _pending_ | |
| 6. Qibla & travel | _pending_ | |
| 7. Widget 2.0 | _pending_ | |
| 8. Insights & Hijri | _pending_ | |
| 9. Update channels | _pending_ | |
| 10. Accessibility | _pending_ | |
| 11. Midnight & clock changes | _pending_ | |

## Blockers found

_None recorded yet._

## Sign-off

Stable `1.0.1` may be declared only when every row is **pass** (or an agreed,
documented non-blocker) and this file is committed with the release commit.
