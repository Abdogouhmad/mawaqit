# Android Home Screen Prayer Widget — OpenCode Implementation Guide

## 1. Goal

The Flutter prayer app is already implemented.

The following are **already working** and must NOT be rebuilt:

- Prayer calculations
- Prayer-time data
- Home-screen UI
- State management
- Repositories/services
- Location/calculation settings
- Existing prayer display

The only missing feature is:

> **An Android Home Screen Widget that displays the necessary prayer information already available in the Flutter home screen.**

The widget should be a small companion to the existing app, not a second prayer application.

---

# 2. Scope

Implement Android Home Screen Widget support.

The first version should display:

- Next/current prayer name
- Prayer time
- Remaining time/countdown
- Optional small contextual information if it already exists in the home screen

Example:

```text
┌──────────────────────────────┐
│  NEXT PRAYER                 │
│                              │
│  Maghrib              19:31  │
│                              │
│       01:24:36 LEFT          │
└──────────────────────────────┘
```

The widget must:

1. Reuse the existing prayer data.
2. Never duplicate prayer calculation logic.
3. Work when the Flutter app is not open.
4. Update when the relevant prayer changes.
5. Move automatically to the next prayer.
6. Handle midnight/day rollover.
7. Open the Flutter app when tapped.

---

# 3. Recommended Architecture

Use:

```text
Existing Flutter prayer state
            │
            ▼
PrayerWidgetService
            │
            ▼
      home_widget
            │
            ▼
Native Android AppWidget
            │
            ▼
Android Home Screen
```

The Flutter application remains the source of truth for prayer data.

The Android widget is only a presentation layer.

Do NOT create a second prayer calculation system in Kotlin.

---

# 4. Recommended Package

Use the Flutter package:

```text
home_widget
```

Before adding it:

1. Inspect `pubspec.yaml`.
2. Check whether a widget package already exists.
3. If one already exists and works, evaluate whether it can be reused.
4. Do not install multiple widget frameworks.
5. Use a current version compatible with the project's Flutter/Dart version.

The exact package version must be determined from the existing project's constraints rather than copied blindly from an old tutorial.

---

# 5. First Inspect the Existing Project

Before modifying code, inspect the project and identify:

### Flutter

- `pubspec.yaml`
- Application entry point
- Home screen
- Prayer model
- Prayer calculation service
- Prayer repository
- Existing state management
- Existing provider/controller/notifier
- Existing date/time utilities
- Existing timezone handling

### Android

- Application ID
- `MainActivity`
- Kotlin package
- Android Gradle configuration
- Minimum SDK
- Compile SDK
- Existing Android dependencies
- Existing manifest

Do not start implementing until you know exactly where the home screen gets its prayer data.

---

# 6. Reuse Existing Home-Screen Data

The most important rule:

> **The widget must consume the same data already used by the Flutter home screen.**

For example, if the home screen already has something equivalent to:

```dart
PrayerState
```

containing:

```text
currentPrayer
nextPrayer
todayPrayers
```

then the widget service should consume that state.

Do NOT create:

```text
WidgetPrayerCalculator
WidgetPrayerRepository
WidgetPrayerProvider
```

unless the existing architecture absolutely requires an adapter.

The widget is not supposed to know how prayer times are calculated.

---

# 7. Create a Small Widget Service

Create a dedicated service following the project's existing folder architecture.

Example:

```text
lib/
└── .../
    └── services/
        └── prayer_widget_service.dart
```

The exact directory should follow the existing project conventions.

Conceptually:

```dart
class PrayerWidgetService {
  Future<void> syncPrayerWidget(PrayerState state) async {
    // Extract already-calculated values.
    // Save them for Android.
    // Request widget update.
  }
}
```

Keep this service small.

It should perform data adaptation, not business logic.

---

# 8. Widget Data Contract

Only publish the data that the widget actually needs.

Recommended minimum:

```text
next_prayer_name
next_prayer_time
next_prayer_timestamp
```

Optional:

```text
current_prayer_name
current_prayer_time
widget_updated_at
```

Do not add fields just because they are available.

The widget should stay simple.

Example:

```text
next_prayer_name = "Maghrib"
next_prayer_time = "19:31"
next_prayer_timestamp = <absolute timestamp>
```

---

# 9. Store a Target Timestamp, NOT a Countdown

This is critical.

Do NOT make the Flutter app continuously calculate:

```text
01:24:36
01:24:35
01:24:34
...
```

Do NOT use a Dart background timer for this.

Instead, store:

```text
next prayer = Maghrib
target timestamp = 19:31
```

The countdown is derived from:

```text
target timestamp - current time
```

This makes the widget robust even if Flutter is completely closed.

---

# 10. Countdown Architecture

Preferred:

```text
Flutter
  │
  │ publishes target timestamp
  ▼
Android Widget
  │
  │ calculates/displays remaining time
  ▼
Home Screen
```

Do NOT rely on:

```dart
Timer.periodic(
  const Duration(seconds: 1),
  ...
)
```

inside Flutter to keep the widget updated.

Android does not allow normal AppWidget periodic updates to behave like an unrestricted one-second background timer.

Where practical, use a native Android mechanism such as `Chronometer` for the visual countdown.

If the chosen implementation cannot provide a continuously updating countdown reliably, prefer a sensible Android-compatible refresh strategy rather than keeping Flutter alive.

---

# 11. Timezone and Timestamp Handling

Prayer times are time-sensitive.

Do not hard-code:

```text
Africa/Casablanca
```

or any other timezone inside the widget unless the existing application explicitly uses that timezone as its source of truth.

Reuse the application's existing date/time and timezone handling.

The widget should receive an unambiguous timestamp.

Good:

```text
epoch milliseconds
```

or:

```text
2026-09-21T19:31:00+01:00
```

Avoid:

```text
2026-09-21 19:31
```

because that has no timezone/offset information.

If the existing application already uses a specific timestamp representation, reuse it consistently.

---

# 12. Android AppWidget

Create a native Android AppWidget.

Expected conceptual structure:

```text
android/
└── app/
    └── src/
        └── main/
            ├── java/
            │   └── <existing-package>/
            │       └── PrayerWidgetProvider.kt
            │
            └── res/
                ├── layout/
                │   └── prayer_widget.xml
                │
                └── xml/
                    └── prayer_widget_info.xml
```

Use Kotlin if the existing Android module uses Kotlin.

Do not change the Android language or architecture unnecessarily.

---

# 13. Android Widget Provider

Create a `PrayerWidgetProvider`.

Responsibilities:

- Read persisted widget data.
- Render the widget.
- Configure the countdown.
- Handle widget lifecycle.
- Handle tap action.
- Request/update the next widget state when needed.

The provider must NOT calculate prayer times.

It should only consume the data published by Flutter.

---

# 14. Widget Layout

Start with a simple layout.

Example:

```text
┌──────────────────────────────┐
│  NEXT PRAYER                 │
│                              │
│  Maghrib              19:31  │
│                              │
│       01:24:36 LEFT          │
└──────────────────────────────┘
```

The exact styling should match the existing application's design language.

Prefer:

- Clear hierarchy
- Large readable prayer name
- Clearly visible prayer time
- Visible countdown
- Compact spacing
- Rounded/container styling if consistent with the app
- Light/dark compatibility
- No unnecessary buttons

Do not reproduce the entire Flutter home screen.

---

# 15. Widget Sizes

Support the launcher sizes that make sense for the design.

At minimum, the widget should remain usable when placed in a normal small/medium launcher area.

Do not assume a single fixed size.

Avoid text overflow.

The layout should gracefully handle:

```text
small widget
medium widget
larger/resized widget
```

If responsive layouts are needed, keep them simple.

---

# 16. Tap Behavior

Tapping the widget should open the Flutter application.

Use an Android `PendingIntent`.

Architecture:

```text
Home Screen Widget
       │
       ▼
PendingIntent
       │
       ▼
MainActivity
       │
       ▼
Flutter application
```

If useful for the existing navigation architecture, pass an action such as:

```text
open_from_widget
```

Do not introduce complicated deep linking unless it provides actual value.

---

# 17. Widget Update Events

The widget should be synchronized when meaningful application data changes.

Consider updating when:

- App starts
- Prayer data is initially loaded
- Prayer data changes
- User changes location
- User changes calculation settings
- User manually refreshes prayer data
- A prayer becomes the next prayer
- A new day begins

Do not rely solely on the Flutter app being open.

Persist the latest widget values.

---

# 18. Prayer Transition

The widget must not remain stuck on an expired prayer.

Example:

Before Maghrib:

```text
NEXT PRAYER

Maghrib
19:31

00:03:42 LEFT
```

After Maghrib:

```text
NEXT PRAYER

Isha
20:48

01:16:18 LEFT
```

The widget should advance to the next prayer.

Reuse the existing application's definition of current/next prayer if one already exists.

Do not create a conflicting definition in the widget.

---

# 19. Midnight / New Day

This is an important test.

At midnight:

```text
Old day prayer data
        ↓
New day prayer data
```

The widget must eventually show the first upcoming prayer of the new day.

Do not leave yesterday's last prayer as the active target.

If the existing app already has a daily refresh mechanism, integrate the widget update with that mechanism rather than creating another independent prayer calculation process.

---

# 20. Missing Data

The widget must fail gracefully.

If data is unavailable, show something like:

```text
Prayer times unavailable

Open app to refresh
```

or another short message consistent with the app.

Never crash because:

- Prayer name is missing
- Timestamp is missing
- Timestamp cannot be parsed
- Widget has been installed before the app has calculated today's prayers
- Flutter has not run recently

---

# 21. Persistence

The widget must be able to render the last known state even when:

```text
Flutter process = killed
```

Do not assume the Flutter application is continuously running.

The widget's data must be persisted using the selected widget integration.

---

# 22. Permissions

Do not add unnecessary permissions.

A basic widget showing already-calculated prayer times does not require new location permissions.

If the existing application already has location handling, leave that system unchanged.

The widget consumes the resulting prayer data.

---

# 23. Do Not Modify Unrelated Features

This task should be isolated.

Do NOT:

- Rewrite prayer calculations
- Rewrite home-screen UI
- Replace state management
- Refactor unrelated services
- Change navigation architecture unnecessarily
- Replace the current design system
- Introduce a new database
- Introduce a backend
- Add unnecessary permissions
- Add unnecessary packages
- Rewrite existing date/time logic

If existing code needs a tiny adapter to expose widget data, make the smallest possible change.

---

# 24. Implementation Order

Follow this exact sequence.

## Step 1 — Inspect

Identify where the existing home screen gets:

```text
next prayer
prayer time
target DateTime
```

Do not modify anything yet.

## Step 2 — Add widget dependency

Only if needed:

```text
home_widget
```

Use a version compatible with the project.

## Step 3 — Create widget service

Create:

```text
PrayerWidgetService
```

It should adapt the existing prayer state into the widget data contract.

## Step 4 — Publish static data

Before implementing a countdown, verify:

```text
Flutter → Android widget → correct prayer name/time
```

## Step 5 — Implement native widget

Create:

```text
PrayerWidgetProvider.kt
prayer_widget.xml
prayer_widget_info.xml
```

Register the provider.

## Step 6 — Add tap behavior

Verify:

```text
Widget tap → Flutter application
```

## Step 7 — Add countdown

Use the target timestamp.

Do not introduce a Flutter one-second background timer.

## Step 8 — Add prayer transition

Verify that after a prayer passes:

```text
current next prayer → following prayer
```

## Step 9 — Add day rollover

Verify midnight behavior.

## Step 10 — Test lifecycle

Test with Flutter closed/killed and with the widget removed/re-added.

---

# 25. Testing Checklist

## Installation

- [ ] Project builds.
- [ ] App installs.
- [ ] Widget appears in Android widget picker.
- [ ] Widget can be added to launcher.

## Data

- [ ] Prayer name matches Flutter home screen.
- [ ] Prayer time matches Flutter home screen.
- [ ] Target timestamp is correct.
- [ ] No duplicated prayer calculation exists.

## Countdown

- [ ] Countdown starts correctly.
- [ ] Countdown is based on target timestamp.
- [ ] Flutter does not need to remain open for the widget to function.
- [ ] Countdown reaches the prayer time.
- [ ] Widget advances to the next prayer.

## Lifecycle

- [ ] Works after Flutter process is killed.
- [ ] Works after reopening the app.
- [ ] Works after widget removal/re-add.
- [ ] Handles day rollover.
- [ ] Does not crash with missing data.

## Interaction

- [ ] Tapping the widget opens the Flutter app.
- [ ] Cold start works.
- [ ] Warm start works.

## UI

- [ ] No text clipping.
- [ ] No overflow.
- [ ] Small widget remains readable.
- [ ] Medium/resized widget remains readable.
- [ ] Light mode is usable.
- [ ] Dark mode is usable.
- [ ] Design matches the existing application.

---

# 26. Important Technical Rules

### Rule 1

The Flutter application is the source of truth.

### Rule 2

The widget is a presentation layer.

### Rule 3

Never duplicate prayer calculations.

### Rule 4

Store an absolute target timestamp, not a countdown string.

### Rule 5

Do not use a one-second Flutter background timer.

### Rule 6

Do not assume Flutter is running.

### Rule 7

Do not hard-code timezone behavior that conflicts with the existing application.

### Rule 8

Keep the implementation isolated.

### Rule 9

Prefer the smallest reliable implementation.

### Rule 10

Test Android lifecycle behavior before considering the feature complete.

---

# 27. Definition of Done

The implementation is complete when a user can:

1. Install the existing prayer app.
2. Add the Prayer Widget from Android's widget picker.
3. See the same next-prayer information displayed by the app.
4. See the correct prayer time.
5. See the remaining time until that prayer.
6. Close/kill the Flutter app and still have a useful widget.
7. Have the widget transition to the next prayer.
8. Cross midnight without stale prayer information.
9. Tap the widget and open the Flutter application.
10. Remove and re-add the widget without crashes.

The implementation should be:

- Minimal
- Android-native where required
- Flutter-integrated
- Reliable
- Easy to maintain
- Reusing existing application data
- Free of duplicated prayer business logic

---

# 28. OpenCode Working Instructions

When implementing this task:

1. **Inspect first.**
2. Identify the existing home-screen prayer data source.
3. Explain briefly which existing classes/providers/services will be reused.
4. Make the smallest implementation necessary.
5. Do not rewrite unrelated code.
6. Build after each major integration step.
7. Fix compile/analyzer errors before continuing.
8. Test the Android widget after static rendering works.
9. Only then implement countdown behavior.
10. Run the existing project's tests/analyzer/build checks before finishing.
11. Report the files changed and why each was changed.
12. Report any Android limitations or assumptions.

If the project already contains an equivalent abstraction for widgets, reuse it rather than introducing another architecture.

The final implementation should feel like a natural extension of the existing prayer app, not a separate subsystem.
