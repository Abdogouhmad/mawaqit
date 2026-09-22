package com.mawaqit.mawaqit

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Compact "next prayer" home-screen widget (plain RemoteViews — no Glance).
 *
 * Flutter is the single source of truth for prayer times. It pushes an
 * unambiguous snapshot through home_widget's `HomeWidgetPreferences` bridge:
 *
 *   - `prayer_schedule` — JSON list of `{name, ts}` for today's prayers plus
 *     tomorrow's Fajr (epoch **ms**). Lets this provider independently advance
 *     to the next prayer and survive midnight even while Flutter is closed.
 *   - `next_prayer_name` / `next_prayer_time` / `next_prayer_ts` — flat mirror
 *     of the immediate target, used as a fallback.
 *
 * The countdown is computed natively from the target timestamp (never a
 * Flutter timer) and refreshed by a self-rescheduling `AlarmManager` tick every
 * five minutes plus every app-driven `APPWIDGET_UPDATE`. Every read is
 * defensive so a malformed/missing row renders a graceful message instead of
 * crashing the widget.
 */
class PrayerWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val ACTION_TICK = "com.mawaqit.action.WIDGET_TICK"
        private const val PREFS = "HomeWidgetPreferences"
        private const val KEY_SCHEDULE = "prayer_schedule"
        private const val KEY_NAME = "next_prayer_name"
        private const val KEY_TIME = "next_prayer_time"
        private const val KEY_TS = "next_prayer_ts"
        private const val REFRESH_MS = 5 * 60_000L

        private fun provider(context: Context): ComponentName =
            ComponentName(context, PrayerWidgetProvider::class.java)

        private fun clock(epochMs: Long): String =
            SimpleDateFormat("HH:mm", Locale.US).format(Date(epochMs))

        private fun startTicker(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerWidgetProvider::class.java)
                .setAction(ACTION_TICK)
            val pendingIntent = tickPendingIntent(context, intent)
            // setAndAllowWhileIdle needs no exact-alarm permission and can fire
            // in Doze, keeping the countdown roughly fresh without waking Flutter.
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + REFRESH_MS,
                pendingIntent,
            )
        }

        private fun stopTicker(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerWidgetProvider::class.java)
                .setAction(ACTION_TICK)
            alarmManager.cancel(tickPendingIntent(context, intent))
        }

        private fun tickPendingIntent(
            context: Context,
            intent: Intent,
        ): PendingIntent = PendingIntent.getBroadcast(
            context,
            0x477,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private data class ScheduledPrayer(val name: String, val ts: Long)

    override fun onEnabled(context: Context) {
        startTicker(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, render(context))
        }
        startTicker(context)
    }

    override fun onDisabled(context: Context) {
        stopTicker(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_TICK) return
        val manager = AppWidgetManager.getInstance(context)
        onUpdate(context, manager, manager.getAppWidgetIds(provider(context)))
    }

    private fun render(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()

        // Tap anywhere on the card opens the app.
        views.setOnClickPendingIntent(
            R.id.widget_root,
            PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).setAction(Intent.ACTION_MAIN),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )

        var name = prefs.getString(KEY_NAME, null).orEmpty()
        var time = prefs.getString(KEY_TIME, null).orEmpty()
        var nextTs = readLong(prefs, KEY_TS, 0L)

        val schedule = parseSchedule(prefs.getString(KEY_SCHEDULE, null))
        if (schedule.isNotEmpty()) {
            var currentTs = 0L
            var next: ScheduledPrayer? = null
            for (prayer in schedule) {
                if (prayer.ts > now) {
                    next = prayer
                    break
                }
                currentTs = prayer.ts
            }
            if (next != null) {
                val target = next
                name = target.name
                time = clock(target.ts)
                nextTs = target.ts

                // Progress from the previous prayer time to the next one.
                val duration = (target.ts - currentTs).coerceAtLeast(1L)
                val elapsed = (now - currentTs).coerceAtLeast(0L)
                val percent = ((elapsed * 100) / duration).toInt().coerceIn(0, 100)
                views.setProgressBar(R.id.widget_progress, 100, percent, false)
                views.setViewVisibility(R.id.widget_progress, View.VISIBLE)
            } else {
                // Every pushed timestamp has passed (schedule more than a day
                // old, Flutter closed) — show the refresh hint, never stale times.
                name = "Prayer times"
                time = "Open app to refresh"
                nextTs = 0L
                views.setViewVisibility(R.id.widget_progress, View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.widget_progress, View.GONE)
        }

        views.setTextViewText(
            R.id.widget_name,
            name.trim().ifEmpty { "Prayer times" },
        )
        views.setTextViewText(
            R.id.widget_time,
            time.trim().ifEmpty { "Open app to refresh" },
        )

        if (nextTs > now) {
            views.setTextViewText(
                R.id.widget_countdown,
                "${formatCountdown(nextTs - now)} LEFT",
            )
            views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_countdown, View.GONE)
        }
        return views
    }

    /// home_widget stores small Dart ints as `int` and large ones as `long`;
    /// read either without tripping SharedPreferences' typed-cast `getLong`.
    private fun readLong(prefs: SharedPreferences, key: String, def: Long): Long {
        val value = prefs.all[key] ?: return def
        return when (value) {
            is Int -> value.toLong()
            is Long -> value
            else -> def
        }
    }

    private fun parseSchedule(raw: String?): List<ScheduledPrayer> {
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            val result = ArrayList<ScheduledPrayer>(array.length())
            for (i in 0 until array.length()) {
                val entry = array.getJSONObject(i)
                val ts = entry.getLong("ts")
                val prayerName = entry.optString("name")
                if (ts > 0 && prayerName.isNotBlank()) {
                    result.add(ScheduledPrayer(prayerName, ts))
                }
            }
            result.sortedBy { it.ts }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun formatCountdown(ms: Long): String {
        val totalSeconds = ms / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return if (hours > 0) {
            String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.US, "%02d:%02d", minutes, seconds)
        }
    }
}