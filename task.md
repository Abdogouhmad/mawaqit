# Instructions — Round 2 Fixes (Mawaqit)

## Agent operating rules
- No long explanations. Work on code directly.
- Run `flutter analyze` after changes, fix issues before moving on.
- Do NOT run or build the app.

---

## FIX 6 — Widget shows nothing when resized to 3x1

Root cause is almost certainly that the Glance widget only defines a single
fixed layout sized for 2x1, and the widget host (launcher) has no fallback
content for other cell sizes — plus missing resize bounds in the provider XML.

Checklist:
- [ ] `res/xml/prayer_widget_info.xml` is missing `minResizeWidth` /
  `minResizeHeight` — without these, some launchers render a blank/error
  state at resized dimensions even if `resizeMode` allows it. Add:
  ```xml
  <appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
      android:minWidth="180dp"
      android:minHeight="90dp"
      android:minResizeWidth="110dp"
      android:minResizeHeight="90dp"
      android:targetCellWidth="2"
      android:targetCellHeight="1"
      android:resizeMode="horizontal|vertical"
      android:widgetCategory="home_screen"
      android:updatePeriodMillis="0"
      android:initialLayout="@layout/glance_default_loading_layout" />
  ```
- [ ] `PrayerWidget.kt` currently uses a single fixed `provideGlance` layout
  with no size awareness. Switch to responsive sizing so 3x1 (and other
  widths) render a valid composable instead of falling through to nothing:
  ```kotlin
  class PrayerWidget : GlanceAppWidget() {

      override val sizeMode = SizeMode.Responsive(
          setOf(
              DpSize(110.dp, 90.dp),  // narrow (3-cell-ish on dense grids)
              DpSize(180.dp, 90.dp),  // default 2x1
              DpSize(260.dp, 90.dp),  // wide 4x1
          )
      )

      override suspend fun provideGlance(context: android.content.Context, id: GlanceId) {
          val prefs = HomeWidgetPlugin.getData(context)
          val prayerName = prefs.getString("next_prayer_name", "—") ?: "—"
          val prayerTime = prefs.getString("next_prayer_time", "") ?: ""
          val minutesLeft = prefs.getInt("minutes_remaining", 0)
          val progress = prefs.getFloat("progress", 0f)

          provideContent {
              val size = LocalSize.current
              PrayerWidgetContent(
                  prayerName = prayerName,
                  prayerTime = prayerTime,
                  minutesLeft = minutesLeft,
                  progress = progress,
                  compact = size.width < 150.dp, // hide subtitle/progress at narrow widths
              )
          }
      }
  }

  @Composable
  fun PrayerWidgetContent(
      prayerName: String,
      prayerTime: String,
      minutesLeft: Int,
      progress: Float,
      compact: Boolean,
  ) {
      Box(
          modifier = GlanceModifier
              .fillMaxSize()
              .background(ColorProvider(0xFF2E7D5B.toInt()))
              .padding(12.dp)
              .cornerRadius(24.dp)
      ) {
          Column(modifier = GlanceModifier.fillMaxSize()) {
              Text(
                  text = prayerName,
                  maxLines = 1,
                  style = TextStyle(
                      color = ColorProvider(0xFFFAFAF7.toInt()),
                      fontSize = if (compact) 16.sp else 20.sp,
                      fontWeight = FontWeight.Bold
                  )
              )
              if (!compact) {
                  Spacer(modifier = GlanceModifier.height(4.dp))
                  Text(
                      text = "in $minutesLeft min • $prayerTime",
                      maxLines = 1,
                      style = TextStyle(color = ColorProvider(0xCCFAFAF7), fontSize = 13.sp)
                  )
              }
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
  ```
  Key points for the agent: use `maxLines = 1` on every `Text` (Glance text
  that overflows its bounds can render as fully clipped/invisible rather
  than truncated depending on host), and branch layout on `LocalSize.current`
  instead of assuming one fixed size always applies.
- [ ] After changing `sizeMode` or the provider XML, the widget must be
  removed and re-added from the home screen to pick up new size metadata —
  note this in a code comment so it isn't mistaken for a runtime bug during
  testing.

---

## FIX 7 — "Test notification" button unavailable

Checklist (work through top to bottom, this is almost always one of these):
- [ ] Confirm the debug trigger is gated on `kDebugMode` only, **not** also
  gated on `Platform.isAndroid` — the whole point of FIX 1 was to make this
  work on Linux too. Search for the button's `visible:`/`if` condition and
  remove any platform check:
  ```dart
  if (kDebugMode)
    ElevatedButton(
      onPressed: () => NotificationService.instance.scheduleTestNotification(),
      child: const Text('Test notification in 10s'),
    ),
  ```
- [ ] Confirm `NotificationService` is fully initialized (`initialize()`
  awaited) before the settings screen builds — if the test button calls a
  method on an uninitialized plugin instance, some platforms silently no-op
  instead of throwing.
- [ ] On Linux specifically: `flutter_local_notifications_linux` requires a
  valid app name matching a registered desktop entry for D-Bus notifications
  to display. If running via `flutter run -d linux` without a proper
  `LinuxInitializationSettings(defaultActionName: 'Open', defaultIcon: ...)`
  and without the app installed as a `.desktop` entry, the call can fail
  silently. Wrap the test call in try/catch and surface the error instead of
  swallowing it:
  ```dart
  Future<void> scheduleTestNotification() async {
    try {
      await notificationsPlugin.zonedSchedule(
        9999,
        'Test notification',
        'This is a pre-prayer alert test',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        const NotificationDetails(
          linux: LinuxNotificationDetails(),
          android: AndroidNotificationDetails(
            'pre_prayer_alert_v2',
            'Pre-prayer alert',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
      rethrow; // let the UI show a SnackBar with the real error instead of nothing happening
    }
  }
  ```
- [ ] If the button is simply missing from the widget tree (not just
  failing), check it wasn't accidentally left inside a `Platform.isAndroid`
  guard block added during FIX 4/5's Android-only permission code — FIX 1
  explicitly required this trigger to stay outside that guard.
- [ ] Add a `SnackBar`/`Text` error surface in the settings screen so any
  future failure here is visible instead of appearing as "unavailable" with
  no signal.

---

## Definition of done
- `flutter analyze` clean, no new errors/warnings
- No `flutter run` / `flutter build` executed
- Widget renders correctly at 2x1, 3x1, and 4x1
- Test notification button visible and functional on Linux debug builds
