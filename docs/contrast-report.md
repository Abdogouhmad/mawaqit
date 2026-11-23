# WCAG contrast report

Generated from the shipped `AppTheme` schemes by `test/contrast_test.dart`.
Every value below is a WCAG 2.2 contrast ratio for an **opaque** foreground on
its paired background; the test fails the build if any pair drops below 4.5:1
(AA for normal text). Large display text only needs 3:1, so the whole UI has
headroom.

Three roles are deliberately audited as text even though they are often used
as accents: `primary/surface` (buttons, selected labels), `tertiary/surface`
(solar facts on the Times tab) and `onSurfaceVariant/surface` (secondary copy).
Those were the pairs that failed before 1.0.0; the gold, amber and sage tokens
were darkened (and dark-sage `onPrimary` switched from white to deep ink) to
bring them into range without changing any colour's meaning.

AMOLED changes only the surface ramp — accents keep their palette colours — so
its ratios are never lower than the matching dark scheme.

| Palette | Mode | Surface | Ratios (foreground/background) |
| --- | --- | --- | --- |
| emerald | light | normal | onPrimary/primary 7.92 · onSurface/surface 16.43 · onSurfaceVariant/surface 4.64 · onPriCont/priCont 11.44 · onSecCont/secCont 7.12 · onTerCont/terCont 7.18 · onError/error 6.46 · onSurface/lowest 17.18 · primary/surface 7.58 · tertiary/surface 4.83 |
| emerald | dark | normal | onPrimary/primary 5.41 · onSurface/surface 15.84 · onSurfaceVariant/surface 5.76 · onPriCont/priCont 8.41 · onSecCont/secCont 6.39 · onTerCont/terCont 7.24 · onError/error 7.72 · onSurface/lowest 15.88 · primary/surface 5.88 · tertiary/surface 10.25 |
| emerald | dark | amoled | onPrimary/primary 5.41 · onSurface/surface 17.90 · onSurfaceVariant/surface 6.51 · onPriCont/priCont 8.41 · onSecCont/secCont 6.39 · onTerCont/terCont 7.24 · onError/error 7.72 · onSurface/lowest 17.90 · primary/surface 6.64 · tertiary/surface 11.58 |
| sage | light | normal | onPrimary/primary 5.00 · onSurface/surface 16.43 · onSurfaceVariant/surface 4.64 · onPriCont/priCont 10.48 · onSecCont/secCont 7.12 · onTerCont/terCont 7.21 · onError/error 6.46 · onSurface/lowest 17.18 · primary/surface 4.78 · tertiary/surface 4.61 |
| sage | dark | normal | onPrimary/primary 5.02 · onSurface/surface 15.84 · onSurfaceVariant/surface 5.76 · onPriCont/priCont 7.43 · onSecCont/secCont 6.39 · onTerCont/terCont 7.17 · onError/error 7.72 · onSurface/lowest 15.88 · primary/surface 5.45 · tertiary/surface 14.38 |
| sage | dark | amoled | onPrimary/primary 5.02 · onSurface/surface 17.90 · onSurfaceVariant/surface 6.51 · onPriCont/priCont 7.43 · onSecCont/secCont 6.39 · onTerCont/terCont 7.17 · onError/error 7.72 · onSurface/lowest 17.90 · primary/surface 6.15 · tertiary/surface 16.25 |
| midnight | light | normal | onPrimary/primary 10.49 · onSurface/surface 16.43 · onSurfaceVariant/surface 4.64 · onPriCont/priCont 12.11 · onSecCont/secCont 7.12 · onTerCont/terCont 7.24 · onError/error 6.46 · onSurface/lowest 17.18 · primary/surface 10.03 · tertiary/surface 4.78 |
| midnight | dark | normal | onPrimary/primary 7.42 · onSurface/surface 15.84 · onSurfaceVariant/surface 5.76 · onPriCont/priCont 7.99 · onSecCont/secCont 6.39 · onTerCont/terCont 7.25 · onError/error 7.72 · onSurface/lowest 15.88 · primary/surface 8.06 · tertiary/surface 10.09 |
| midnight | dark | amoled | onPrimary/primary 7.42 · onSurface/surface 17.90 · onSurfaceVariant/surface 6.51 · onPriCont/priCont 7.99 · onSecCont/secCont 6.39 · onTerCont/terCont 7.25 · onError/error 7.72 · onSurface/lowest 17.90 · primary/surface 9.11 · tertiary/surface 11.40 |
| ocean | light | normal | onPrimary/primary 6.45 · onSurface/surface 16.30 · onSurfaceVariant/surface 8.87 · onPriCont/priCont 7.23 · onSecCont/secCont 7.22 · onTerCont/terCont 7.27 · onError/error 6.46 · onSurface/lowest 17.10 · primary/surface 6.15 · tertiary/surface 6.19 |
| ocean | dark | normal | onPrimary/primary 7.71 · onSurface/surface 14.28 · onSurfaceVariant/surface 10.89 · onPriCont/priCont 7.24 · onSecCont/secCont 7.25 · onTerCont/terCont 7.24 · onError/error 7.72 · onSurface/lowest 14.93 · primary/surface 10.88 · tertiary/surface 10.84 |
| ocean | dark | amoled | onPrimary/primary 7.71 · onSurface/surface 16.21 · onSurfaceVariant/surface 12.36 · onPriCont/priCont 7.24 · onSecCont/secCont 7.25 · onTerCont/terCont 7.24 · onError/error 7.72 · onSurface/lowest 16.21 · primary/surface 12.35 · tertiary/surface 12.31 |
| violet | light | normal | onPrimary/primary 6.48 · onSurface/surface 16.34 · onSurfaceVariant/surface 8.88 · onPriCont/priCont 7.22 · onSecCont/secCont 7.20 · onTerCont/terCont 7.26 · onError/error 6.46 · onSurface/lowest 17.16 · primary/surface 6.17 · tertiary/surface 6.18 |
| violet | dark | normal | onPrimary/primary 7.75 · onSurface/surface 14.37 · onSurfaceVariant/surface 10.93 · onPriCont/priCont 7.22 · onSecCont/secCont 7.20 · onTerCont/terCont 7.26 · onError/error 7.72 · onSurface/lowest 14.94 · primary/surface 10.92 · tertiary/surface 10.90 |
| violet | dark | amoled | onPrimary/primary 7.75 · onSurface/surface 16.26 · onSurfaceVariant/surface 12.36 · onPriCont/priCont 7.22 · onSecCont/secCont 7.20 · onTerCont/terCont 7.26 · onError/error 7.72 · onSurface/lowest 16.26 · primary/surface 12.35 · tertiary/surface 12.34 |
| rose | light | normal | onPrimary/primary 6.44 · onSurface/surface 16.37 · onSurfaceVariant/surface 8.90 · onPriCont/priCont 7.20 · onSecCont/secCont 7.25 · onTerCont/terCont 7.22 · onError/error 6.46 · onSurface/lowest 17.17 · primary/surface 6.14 · tertiary/surface 6.18 |
| rose | dark | normal | onPrimary/primary 7.69 · onSurface/surface 14.42 · onSurfaceVariant/surface 10.95 · onPriCont/priCont 7.22 · onSecCont/secCont 7.24 · onTerCont/terCont 7.26 · onError/error 7.72 · onSurface/lowest 14.98 · primary/surface 10.93 · tertiary/surface 10.91 |
| rose | dark | amoled | onPrimary/primary 7.69 · onSurface/surface 16.31 · onSurfaceVariant/surface 12.38 · onPriCont/priCont 7.22 · onSecCont/secCont 7.24 · onTerCont/terCont 7.26 · onError/error 7.72 · onSurface/lowest 16.31 · primary/surface 12.36 · tertiary/surface 12.34 |
| amber | light | normal | onPrimary/primary 6.47 · onSurface/surface 16.35 · onSurfaceVariant/surface 8.87 · onPriCont/priCont 7.22 · onSecCont/secCont 7.28 · onTerCont/terCont 7.21 · onError/error 6.46 · onSurface/lowest 17.18 · primary/surface 6.16 · tertiary/surface 6.15 |
| amber | dark | normal | onPrimary/primary 7.71 · onSurface/surface 14.33 · onSurfaceVariant/surface 10.82 · onPriCont/priCont 7.24 · onSecCont/secCont 7.26 · onTerCont/terCont 7.25 · onError/error 7.72 · onSurface/lowest 14.99 · primary/surface 10.84 · tertiary/surface 10.85 |
| amber | dark | amoled | onPrimary/primary 7.71 · onSurface/surface 16.29 · onSurfaceVariant/surface 12.30 · onPriCont/priCont 7.24 · onSecCont/secCont 7.26 · onTerCont/terCont 7.25 · onError/error 7.72 · onSurface/lowest 16.29 · primary/surface 12.33 · tertiary/surface 12.33 |
| terracotta | light | normal | onPrimary/primary 6.46 · onSurface/surface 16.36 · onSurfaceVariant/surface 8.92 · onPriCont/priCont 7.25 · onSecCont/secCont 7.23 · onTerCont/terCont 7.25 · onError/error 6.46 · onSurface/lowest 17.17 · primary/surface 6.15 · tertiary/surface 6.15 |
| terracotta | dark | normal | onPrimary/primary 7.75 · onSurface/surface 14.33 · onSurfaceVariant/surface 10.86 · onPriCont/priCont 7.24 · onSecCont/secCont 7.24 · onTerCont/terCont 7.30 · onError/error 7.72 · onSurface/lowest 14.99 · primary/surface 10.88 · tertiary/surface 10.88 |
| terracotta | dark | amoled | onPrimary/primary 7.75 · onSurface/surface 16.29 · onSurfaceVariant/surface 12.35 · onPriCont/priCont 7.24 · onSecCont/secCont 7.24 · onTerCont/terCont 7.30 · onError/error 7.72 · onSurface/lowest 16.29 · primary/surface 12.37 · tertiary/surface 12.37 |
| graphite | light | normal | onPrimary/primary 6.49 · onSurface/surface 16.30 · onSurfaceVariant/surface 8.90 · onPriCont/priCont 7.28 · onSecCont/secCont 7.27 · onTerCont/terCont 7.21 · onError/error 6.46 · onSurface/lowest 17.10 · primary/surface 6.18 · tertiary/surface 6.15 |
| graphite | dark | normal | onPrimary/primary 7.71 · onSurface/surface 14.28 · onSurfaceVariant/surface 10.89 · onPriCont/priCont 7.24 · onSecCont/secCont 7.25 · onTerCont/terCont 7.23 · onError/error 7.72 · onSurface/lowest 14.86 · primary/surface 10.86 · tertiary/surface 10.89 |
| graphite | dark | amoled | onPrimary/primary 7.71 · onSurface/surface 16.21 · onSurfaceVariant/surface 12.36 · onPriCont/priCont 7.24 · onSecCont/secCont 7.25 · onTerCont/terCont 7.23 · onError/error 7.72 · onSurface/lowest 16.21 · primary/surface 12.33 · tertiary/surface 12.36 |
