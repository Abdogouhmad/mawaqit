# Project Spec — Minimal Android Prayer Times App (Flutter)

## Scope
Personal/family app. Only: prayer times display + countdown + local notifications. No account system, no backend, no social features.

## Platform
Android only, Flutter.

## Core packages
```yaml
dependencies:
  flutter_riverpod: ^2.5.1        # state management
  adhan_dart: ^1.1.0              # prayer time calculation (offline, no API)
  geolocator: ^13.0.1             # device location
  geocoding: ^3.0.0               # reverse geocode for display name
  flutter_local_notifications: ^17.2.3
  workmanager: ^0.5.2             # reliable background scheduling
  shared_preferences: ^2.3.2      # settings persistence
  hive: ^2.2.3                    # optional local cache of times
  hive_flutter: ^1.1.0
  intl: ^0.19.0                   # date/time formatting + Hijri
  hijri: ^3.0.0                   # Hijri calendar
  audioplayers: ^6.1.0            # adhan sound playback
```

## Project structure
```
lib/
├── main.dart
├── app.dart                      # MaterialApp, theme, router
├── core/
│   ├── constants.dart
│   ├── theme/
│   │   ├── app_theme.dart        # M3 light + dark ThemeData
│   │   └── colors.dart
│   └── utils/
│       └── time_formatter.dart
├── data/
│   ├── models/
│   │   ├── prayer_time.dart
│   │   └── app_settings.dart
│   ├── repositories/
│   │   ├── location_repository.dart
│   │   ├── prayer_times_repository.dart   # wraps adhan_dart
│   │   └── settings_repository.dart       # shared_preferences
│   └── services/
│       ├── notification_service.dart      # flutter_local_notifications setup
│       └── background_scheduler.dart      # workmanager tasks
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── widgets/
│   │   │   ├── countdown_widget.dart
│   │   │   └── prayer_list_tile.dart
│   │   └── home_controller.dart           # riverpod StateNotifier/AsyncNotifier
│   └── settings/
│       ├── settings_screen.dart
│       └── settings_controller.dart
└── providers/
    └── providers.dart                     # riverpod provider declarations
```

## Architecture
- Riverpod for state; feature folders each own a controller + screen + widgets
- Repository pattern isolates `adhan_dart`, location, and notification plumbing from UI
- No REST API, no server — all computation on-device via `adhan_dart`

## Key logic

### Prayer time calculation
- Use `adhan_dart`'s `PrayerTimes` with `Coordinates` from `geolocator` + chosen `CalculationMethod`
- Recalculate daily at midnight (local) via `workmanager` periodic task
- Cache today's/tomorrow's times in Hive to avoid recompute on cold start

### Notifications
- On settings save or daily recompute: schedule 5 exact `flutter_local_notifications` alarms (one per prayer) for the day, offset by user's lead-time preference
- Use `AndroidScheduleMode.exactAllowWhileIdle`
- Request `SCHEDULE_EXACT_ALARM` / `POST_NOTIFICATIONS` permissions on Android 13+

### Background reliability
- `workmanager` periodic task (~daily) re-schedules next day's notifications; guards against device reboot clearing exact alarms
- Register a boot-completed receiver equivalent via `workmanager`'s registerPeriodicTask at app init

### Settings persisted (shared_preferences)
- `calculationMethod` (enum)
- `notificationLeadMinutes` (int)
- `adhanSoundEnabled` (bool), `adhanSoundAsset` (string)
- `themeMode` (system/light/dark)
- `manualLocation` (lat/lng, nullable — null = auto/GPS)

## Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

## Explicit non-goals
- No Quran text/quotes module
- No Qibla compass
- No community/social/donation features
- No cloud sync/accounts
- No multi-language beyond device locale + Arabic/English toggle if trivial

## Custom lockscreen notification (rich card w/ progress bar)

Default `flutter_local_notifications` styles (BigText, Inbox) can't produce the
rounded card + progress bar + action buttons layout. Use a custom RemoteViews
layout via native Android + `DecoratedCustomViewStyle`.

`android/app/src/main/res/layout/notification_prayer.xml`
```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/notif_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textStyle="bold"
        android:textSize="16sp" />

    <TextView
        android:id="@+id/notif_subtitle"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="13sp" />

    <ProgressBar
        android:id="@+id/notif_progress"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="6dp"
        android:layout_marginTop="8dp"
        android:progressTint="#2E7D5B" />
</LinearLayout>
```

Kotlin (`MainActivity.kt` or a plugin method channel handler):
```kotlin
val remoteViews = RemoteViews(packageName, R.layout.notification_prayer).apply {
    setTextViewText(R.id.notif_title, "Maghrib in 10 minutes")
    setTextViewText(R.id.notif_subtitle, "Prayer time is at 6:15 PM • Sunset at 6:14 PM")
    setProgressBar(R.id.notif_progress, 100, elapsedPercent, false)
}

val muteIntent = /* PendingIntent -> BroadcastReceiver that mutes this adhan */
val dismissIntent = /* PendingIntent -> cancels notification */

val notification = NotificationCompat.Builder(context, CHANNEL_ID)
    .setSmallIcon(R.drawable.ic_notification)
    .setStyle(NotificationCompat.DecoratedCustomViewStyle())
    .setCustomContentView(remoteViews)
    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
    .addAction(R.drawable.ic_mute, "Mute this adhan", muteIntent)
    .addAction(R.drawable.ic_dismiss, "Dismiss", dismissIntent)
    .setOngoing(true) // keeps it pinned until prayer time passes
    .build()

NotificationManagerCompat.from(context).notify(notificationId, notification)
```

Bridge from Flutter via a `MethodChannel` (`flutter_local_notifications` doesn't
expose `DecoratedCustomViewStyle`), triggered by the same `workmanager`
scheduled task that computes prayer times.

To animate/update the progress bar every minute while the notification is
showing, re-post via `NotificationManagerCompat.notify()` with updated progress
on a periodic `AlarmManager` tick (exact alarms already used for prayer times).

## Build target
- `minSdkVersion 23`, `targetSdkVersion` latest stable
- Single APK, no flavors needed unless family wants a shared build vs personal build
