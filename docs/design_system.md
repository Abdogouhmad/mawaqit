# Design system 2.0

The visual language for 0.17.0 and every screen after it: **quiet paper, one
signal colour, hairline structure**. The app should look calm rather than
decorated — a warm off-white/dark canvas, tonal surfaces, one emerald accent
that means "action or selection", and 1dp hairlines that do the separating.
No gradients on ordinary surfaces, no glow for its own sake, no second accent
competing with the brand.

This is a token-and-primitive contract, not a style guide with screenshots. If a
value is repeated in two widgets, it becomes a token; if a layout is repeated in
two screens, it becomes a primitive.

## Import

Component code imports one façade:

```dart
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
```

It exports the four owners of the vocabulary:

| File | Owns |
| --- | --- |
| `app_colors.dart` | Raw colours and the selectable [AppPalette]s. No dynamic colour. |
| `shapes.dart` | `AppSpacing`, `AppRadius`, `AppFontSize`, `AppIconSize`. |
| `motion.dart` | `AppMotion` (appear/disappear) and `AppSpring` (movement and accessibility). |
| `effects.dart` | `AppOpacity`, `AppStroke`, `AppElevation`, `AppBlur`, `AppSize`, `AppLayout`, `AppShape`, `AppWeight`, `AppTypeDetail`. |

Widget files must not spell a hex colour, a raw alpha, a `Duration`, a `Curve`
or a one-off pixel size. The token files are the only place raw values live.
`UiText` maps semantic text roles to the `TextTheme`, so widgets pick
`UiTextType` rather than a font size.

## Rules that matter in review

- **Colour comes from the scheme.** Pick `scheme.primary`, `scheme.surfaceContainer`,
  etc.; only soften it with an `AppOpacity` token. `AppColors` is for the theme
  assembly and native mirrors, not for widgets.
- **Selection uses `primaryContainer`.** The selected navigation indicator and
  selected icon/label use `onPrimaryContainer`. This is the role the palette
  tests guard, so it follows every user-selected palette.
- **Elevation is almost zero.** Cards have a hairline border and one very soft
  ambient shadow. Dividers use `AppOpacity.hairline`; never invent a new grey.
- **Motion has two families.** `AppMotion` for fades and appearances,
  `AppSpring` for spatial movement. Read `AppSpring.isDisabled(context)` before
  starting anything continuous — the platform setting and the in-app switch are
  OR-ed together.
- **RTL is structural.** Use `EdgeInsetsDirectional`/`AlignmentDirectional` for
  leading/trailing geometry, and let `NavigationBar` lay destinations out in
  logical order. Arabic text keeps zero tracking via `AppTextTheme.untacked()`.
- **200% text is the default bar.** Two-column rows wrap on both sides; a
  trailing control and a title are both `Flexible`. Test at 360dp and 388dp in
  EN/FR/AR at 1x and 2x before calling a primitive done.

## Primitives

All are in `lib/shared` unless noted:

| Primitive | Purpose |
| --- | --- |
| `AppCard` | The single tonal container with hairline border and optional tap. |
| `SectionHeader` | Icon + uppercase label + optional caption/trailing action. |
| `AppListRow` | Generic leading/title/subtitle/trailing row. |
| `SettingsRow`, `SettingsGroup`, `InfoRow` | Settings-specific and detail-row adapters over the same geometry. |
| `AppPill`, `IconBadge` | Status/badge vocabulary; the only capsule labels. |
| `EmptyState` (`core/ui/widgets`) | Quiet "nothing here" with an optional way out. |
| `AppLoadingState` | In-place progress with an optional label. |
| `AppIconButton` | Standard/tonal/filled icon actions with one 48dp target. |
| `SegmentedControl<T>` | Sliding-pill choice for two to four short options. |
| `AppButton` | Filled/tonal/outlined/text actions with inline loading state. |
| `AppNavigationBar` | The only bottom-navigation chrome; used by `AppShell`. |

`test/design_system_gallery_test.dart` pumps every primitive at 360/388dp,
EN/AR, light/dark and 1x/2x. `test/bottom_nav_test.dart` pins the destination
labels, tooltips, semantics and router wiring; `test/tab_layout_test.dart`
remains the end-to-end overflow guard for the real shell.

## App shell

`AppShell` is deliberately thin: it chooses the tab body, wraps it in
`AppChrome.constrain`, and hands `AppNavigationBar` the localized destinations
and the current index. Do not reintroduce a detached floating bar or a local
`NavigationBarTheme` in a screen — the `Scaffold` owns the reserved height and
the shared widget owns the styling.

## Removing things

When a phase replaces a pattern, delete the old copy in the same commit. The
0.17 pass removed `AppChrome.screenPadding`, the hand-built navigation bar in
`app_shell.dart`, the duplicated leading-icon circle in `SettingsRow`, and the
unused `Chip`/`Card`/`SegmentedButton` theme blocks. A second implementation may
survive for one release only when it is explicitly documented as a migration
step; there is no such case here.
