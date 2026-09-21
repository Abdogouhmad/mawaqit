# Instructions — Mawaqit (Flutter Android Prayer App)

## Agent operating rules
- Do not write long explanations. Work on code directly.
- After each change, run `flutter analyze` and fix reported issues before moving on.
- Do NOT run or build the app (no `flutter run`, no `flutter build`).
- Rename everywhere: app was previously called "Waqt" — rename to **Mawaqit**
  (package id, app label in `AndroidManifest.xml`, `pubspec.yaml` `name:`,
  Kotlin package path `com.yourpackage.waqt` → `com.yourpackage.mawaqit`,
  any string literals, folder/class names referencing `waqt`).

---

## FIX 1 — Cross-platform notification testing (Linux first, Android later)
Pre-prayer notifications must be testable on Linux desktop before packaging an
Android APK.

- Add Linux backend for `flutter_local_notifications`:
  ```yaml
  dependencies:
    flutter_local_notifications: ^17.2.3
    flutter_local_notifications_linux: ^5.0.0 # if not bundled already
  ```
- `notification_service.dart` must initialize per-platform:
  ```dart
  final linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');
  final androidSettings = AndroidInitializationSettings('ic_notification');
  final initSettings = InitializationSettings(
    android: androidSettings,
    linux: linuxSettings,
  );
  await notificationsPlugin.initialize(initSettings);
  ```
- Scheduling logic (`zonedSchedule`) must be platform-agnostic — no
  Android-only APIs in the shared scheduling path. Android-only details
  (custom RemoteViews card, exact-alarm permission) go behind
  `if (Platform.isAndroid)` guards, not in the shared code path, so the same
  scheduling logic is verifiable on Linux.
- Add a debug-only trigger (e.g. a settings screen button "Test notification
  in 10s") so pre-prayer alerts can be verified on Linux without waiting for
  an actual prayer time.

## FIX 2 — Separate sounds: pre-prayer alert vs. adhan
Two distinct Android notification channels (channels are immutable after
creation — if they already exist with the old single-sound config, bump the
channel ID so Android creates fresh ones):

```dart
const preAlertChannel = AndroidNotificationChannel(
  'pre_prayer_alert_v2',
  'Pre-prayer alert',
  sound: RawResourceAndroidNotificationSound('pre_alert'), // short chime
  importance: Importance.high,
);

const adhanChannel = AndroidNotificationChannel(
  'prayer_adhan_v2',
  'Prayer call (adhan)',
  sound: RawResourceAndroidNotificationSound('adhan'), // full adhan clip
  importance: Importance.max,
  audioAttributesUsage: AudioAttributesUsage.alarm,
);
```
- Place sound files at `android/app/src/main/res/raw/pre_alert.<ext>` and
  `android/app/src/main/res/raw/adhan.<ext>`.
- `notification_service.dart` must pick the channel based on notification
  type (`NotificationType.preAlert` vs `NotificationType.adhan`), not reuse
  one channel for both.
- On Linux, map both types to `LinuxNotificationSound` equivalents (or a
  no-op stub) so the platform-agnostic scheduler code doesn't branch on
  channel details directly — keep that behind the same `Platform.isAndroid`
  guard from FIX 1.

## FIX 3 — Notification firing at wrong time
Root-cause checklist for the agent to verify against the current code:
- [ ] All scheduled times must be built with `tz.TZDateTime` (from the
  `timezone` package), not `DateTime`, and the local timezone must be set via
  `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`
  at app start — a naive `DateTime` passed to `zonedSchedule` is a common
  cause of off-by-timezone-offset firing.
- [ ] `androidScheduleMode` must be `AndroidScheduleMode.exactAllowWhileIdle`,
  not `inexact` — inexact mode can drift by minutes and is batched by Doze.
- [ ] Verify the pre-prayer alert offset is subtracted from the correct
  prayer time (`prayerTime.subtract(Duration(minutes: leadMinutes))`), not
  added, and not applied twice if both the daily recompute and the settings-
  change handler reschedule the same notification.
- [ ] After a daily recompute (`workmanager` task), old pending notifications
  for that day must be cancelled (`cancel(id)`) before new ones are
  scheduled, to avoid stale double-fires at the old time.
- [ ] Confirm each prayer's notification `id` is deterministic and unique
  per day (e.g. `hash(prayerName + dateString)`), not reused across days in a
  way that silently drops the reschedule.

## FIX 4 — Lock screen notification card (custom RemoteViews)
Currently not shown on lock screen. Fix:
- Add permissions to `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
  ```
- Request `POST_NOTIFICATIONS` at runtime on Android 13+ (API 33+) before
  the first scheduled notification — not just declared in the manifest.
- On the `NotificationCompat.Builder` (native custom-view path from the
  earlier spec), set:
  ```kotlin
  .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
  ```
  Without this, the system defaults to hiding content on a locked device.
- Sync trigger: the custom RemoteViews card (title, subtitle, progress bar)
  must be posted at **pre-prayer alert time**, not at adhan time — i.e. wire
  it into the FIX-2 `pre_prayer_alert` path, not the `prayer_adhan` path.
- Progress bar value must be computed as elapsed-fraction between "alert
  posted" and "prayer time reached", updated via periodic re-notify (see
  earlier `prayer-app-spec.md` custom notification section for the
  `AlarmManager` tick approach) — do not leave it static at 0.

## FIX 5 — Functional, clickable notification: mute a specific prayer
The "Mute this adhan" action must actually mute that one prayer occurrence,
not just dismiss the notification.

- Add a `BroadcastReceiver` for the mute action:
  ```kotlin
  class MutePrayerReceiver : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
          val prayerId = intent.getStringExtra("prayer_id") ?: return
          // persist muted state for this specific occurrence (date + prayer name)
          MutedPrayerStore.setMuted(context, prayerId, true)
          NotificationManagerCompat.from(context).cancel(intent.getIntExtra("notif_id", 0))
      }
  }
  ```
- `prayer_id` must encode date + prayer name (e.g. `"2026-09-21_maghrib"`) so
  muting today's Maghrib doesn't mute tomorrow's.
- Register the receiver in `AndroidManifest.xml` with `android:exported="false"`.
- Before firing the `adhan` sound notification (FIX 2/3 path), check
  `MutedPrayerStore.isMuted(prayerId)` and skip sound (or skip the
  notification entirely, per product decision — default: still show silent
  notification, skip sound) if muted.
- Mute state must be readable from Flutter (via `MethodChannel` or the same
  `shared_preferences`/Hive store) so the in-app prayer list can also show a
  muted indicator, not just the native side.

---

## FEAT — Home screen widget (small rectangle prayer card)

### Goal
Small rectangle widget (2x1 cell grid, resizable to 4x1) showing next prayer
name, countdown, and time. Same visual language as the app (sage green
accent, minimal).

### Approach
Jetpack Glance (Compose-based widget framework), synced from Flutter via the
`home_widget` package.

### Packages
```yaml
# pubspec.yaml
dependencies:
  home_widget: ^0.7.0
```
```kotlin
// android/app/build.gradle.kts
dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")
}
```

### Data flow
```
Flutter (home_controller.dart)
   -> computes next prayer via adhan_dart
   -> HomeWidget.saveWidgetData('next_prayer_name', 'Maghrib')
   -> HomeWidget.saveWidgetData('next_prayer_time', '6:15 PM')
   -> HomeWidget.saveWidgetData('minutes_remaining', 10)
   -> HomeWidget.saveWidgetData('progress', 0.66)
   -> HomeWidget.updateWidget(androidName: 'PrayerWidgetReceiver')
        v
Android Glance widget reads via home_widget's SharedPreferences bridge and renders.
```

### Flutter side
```dart
// lib/data/services/widget_service.dart
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> updateWidget({
    required String prayerName,
    required String prayerTime,
    required int minutesRemaining,
    required double progress,
  }) async {
    await HomeWidget.saveWidgetData('next_prayer_name', prayerName);
    await HomeWidget.saveWidgetData('next_prayer_time', prayerTime);
    await HomeWidget.saveWidgetData('minutes_remaining', minutesRemaining);
    await HomeWidget.saveWidgetData('progress', progress);
    await HomeWidget.updateWidget(
      androidName: 'PrayerWidgetReceiver',
      qualifiedAndroidName: 'com.yourpackage.mawaqit.PrayerWidgetReceiver',
    );
  }
}
```
Call from the same place the notification scheduler recomputes prayer times
(daily `workmanager` task) and once on app start.

### Android side

`PrayerWidget.kt`
```kotlin
package com.yourpackage.mawaqit

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: android.content.Context, id: GlanceId) {
        val prefs = HomeWidgetPlugin.getData(context)
        val prayerName = prefs.getString("next_prayer_name", "—") ?: "—"
        val prayerTime = prefs.getString("next_prayer_time", "") ?: ""
        val minutesLeft = prefs.getInt("minutes_remaining", 0)
        val progress = prefs.getFloat("progress", 0f)

        provideContent {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(0xFF2E7D5B.toInt()))
                    .padding(16.dp)
                    .cornerRadius(24.dp)
            ) {
                Column(modifier = GlanceModifier.fillMaxSize()) {
                    Text(
                        text = prayerName,
                        style = TextStyle(
                            color = ColorProvider(0xFFFAFAF7.toInt()),
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = "in $minutesLeft min • $prayerTime",
                        style = TextStyle(color = ColorProvider(0xCCFAFAF7), fontSize = 13.sp)
                    )
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    LinearProgressIndicator(
                        progress = progress,
                        modifier = GlanceModifier.fillMaxWidth().height(6.dp),
                        color = ColorProvider(0xFFFAFAF7.toInt()),
                        backgroundColor = ColorProvider(0x33FAFAF7)
                    )
                }
            }
        }
    }
}
```

`PrayerWidgetReceiver.kt`
```kotlin
package com.yourpackage.mawaqit

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class PrayerWidgetReceiver : HomeWidgetGlanceWidgetReceiver<PrayerWidget>() {
    override val glanceAppWidget: PrayerWidget = PrayerWidget()
}
```

`AndroidManifest.xml`
```xml
<receiver
    android:name=".PrayerWidgetReceiver"
    android:exported="false"
    android:label="Mawaqit — Next Prayer">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/prayer_widget_info" />
</receiver>
```

`res/xml/prayer_widget_info.xml`
```xml
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="90dp"
    android:targetCellWidth="2"
    android:targetCellHeight="1"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/glance_default_loading_layout" />
```
`updatePeriodMillis="0"` — updates pushed manually via `HomeWidget.updateWidget()`,
not Android's own poll cycle.

### Update cadence
- Full recompute + widget push: daily (midnight) via existing `workmanager` task
- Extra push: on each prayer transition (5x/day) so "next prayer" flips
  immediately, scheduled via the same exact-alarm mechanism as notifications
- No live-ticking countdown inside the widget — static text refreshed at each
  push, not a real-time timer

### Note
`home_widget`'s Glance receiver classes live under `es.antonborri.home_widget`
in current versions — verify the exact package path against the installed
plugin version before wiring imports.

---

## Definition of done
- `flutter analyze` reports no new errors/warnings introduced by these changes
- No `flutter run` / `flutter build` executed by the agent
- All `waqt` naming replaced with `mawaqit` project-wide
- Each FIX section's checklist items addressed in code (not just commented)
