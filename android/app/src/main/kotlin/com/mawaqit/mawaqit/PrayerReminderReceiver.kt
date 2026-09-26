package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject
import kotlin.math.ceil

/**
 * Shows and live-updates the decorated reminder card, then flips to a
 * "prayer time" notification when the prayer entry passes.
 */
class PrayerReminderReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PrayerReminder"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(PrayerScheduler.EXTRA_ID, -1)
        if (id == -1) return

        when (intent.action) {
            PrayerScheduler.ACTION_MUTE, PrayerScheduler.ACTION_DISMISS ->
                handleAction(context, id)
            else ->
                if (intent.action == PrayerScheduler.ACTION_SHOW) {
                    handleShow(context, id, intent.getStringExtra(PrayerScheduler.EXTRA_REMINDER))
                }
        }
    }

    private fun handleAction(context: Context, id: Int) {
        PrayerScheduler.cancelAlarm(context, id)
        NotificationManagerCompat.from(context).cancel(id)
        PrayerScheduler.removePref(context, id)
    }

    /**
     * Posts the card for [id] and re-arms itself a minute later so the
     * countdown keeps ticking.
     *
     * [payloadFallback] is the copy carried by the alarm intent: when the stored
     * entry is gone (a reschedule whose async write never landed, or prefs
     * cleared by a later schedule) the card is still shown instead of the
     * occurrence being dropped silently.
     */
    fun handleShow(context: Context, id: Int, payloadFallback: String? = null) {
        val prefs = context.getSharedPreferences(PrayerScheduler.PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString("reminder_$id", null) ?: payloadFallback ?: return
        val data = try {
            JSONObject(raw)
        } catch (_: Exception) {
            return
        }
        val name = data.optString(PrayerScheduler.EXTRA_NAME, "Prayer")
        val prayerMs = data.optLong(PrayerScheduler.EXTRA_PRAYER_MS, 0L)
        if (prayerMs == 0L) return
        val leadMin = data.optInt(PrayerScheduler.EXTRA_LEAD_MIN, 10)
        val now = System.currentTimeMillis()

        // The channel is re-created from the payload rather than read from the
        // shared prefs key: `notify()` on a channel that does not exist is a
        // silent no-op, which is exactly how the pre-prayer card could vanish
        // without a trace. Entries armed before this release carry no sound, so
        // they fall back to the day-level choice instead of going mute.
        val sound = data.optString(PrayerScheduler.EXTRA_SOUND).takeIf { it.isNotBlank() }
            ?: prefs.getString(PrayerScheduler.KEY_CHANNEL_SOUND, "silent")
            ?: "silent"
        PrayerScheduler.ensureReminderChannel(context, sound)
        val channelId = PrayerScheduler.channelIdFor(sound)

        if (!AlarmAccess.hasNotifications(context)) {
            Log.w(
                TAG,
                "Notifications are disabled for ${context.packageName} — " +
                    "the pre-prayer card for $name cannot be posted.",
            )
            PrayerScheduler.cancelAlarm(context, id)
            return
        }

        if (now >= prayerMs) {
            PrayerScheduler.cancelAlarm(context, id)
            PrayerScheduler.removePref(context, id)
            showPrayerTimeNotification(context, id, channelId, name, prayerMs)
            return
        }

        // Progress bar calculation: fraction of the pre-prayer lead interval elapsed towards prayer entry
        val leadStartMs = prayerMs - leadMin * 60_000L
        val totalMs = prayerMs - leadStartMs
        val elapsedMs = now - leadStartMs
        val percent = if (totalMs > 0) {
            (elapsedMs * 100 / totalMs).toInt().coerceIn(0, 100)
        } else {
            0
        }

        val remainingMin = ceil((prayerMs - now) / 60_000.0).toInt()
        val title = if (remainingMin > 1) {
            context.getString(R.string.notif_title_in_min, name, remainingMin)
        } else if (remainingMin == 1) {
            context.getString(R.string.notif_title_in_one_min, name)
        } else {
            context.getString(R.string.notif_now, name)
        }

        val time = PrayerScheduler.timeLabel(prayerMs)
        val sunsetMs = prefs.getLong(PrayerScheduler.KEY_SUNSET, 0L)
        val subtitle = if (name.equals("Maghrib", ignoreCase = true) && sunsetMs > 0L) {
            context.getString(
                R.string.notif_subtitle_with_sunset,
                time,
                PrayerScheduler.timeLabel(sunsetMs),
            )
        } else {
            context.getString(R.string.notif_subtitle, time)
        }

        val sunriseMs = prefs.getLong(PrayerScheduler.KEY_SUNRISE, 0L)
        val fajrMs = prefs.getLong(PrayerScheduler.KEY_FAJR, 0L)

        // Collapsed notification view (avoids vertical clipping on Android 12+ / Pixel 9 lockscreen)
        val collapsedViews = RemoteViews(context.packageName, R.layout.notification_prayer_collapsed).apply {
            setTextViewText(R.id.notif_title, title)
            setTextViewText(R.id.notif_subtitle, subtitle)
            setProgressBar(R.id.notif_progress, 100, percent, false)
        }

        // Expanded notification view (Stitch system tray mock design with actions and ambient footer)
        val views = RemoteViews(context.packageName, R.layout.notification_prayer).apply {
            setTextViewText(R.id.notif_title, title)
            setTextViewText(R.id.notif_subtitle, subtitle)
            setProgressBar(R.id.notif_progress, 100, percent, false)
            if (sunriseMs > 0L) {
                setTextViewText(
                    R.id.notif_sunrise,
                    context.getString(
                        R.string.notif_sunrise,
                        PrayerScheduler.timeLabel(sunriseMs),
                    ),
                )
            }
            if (fajrMs > 0L) {
                setTextViewText(
                    R.id.notif_fajr,
                    context.getString(
                        R.string.notif_fajr,
                        PrayerScheduler.timeLabel(fajrMs),
                    ),
                )
            }
            if (sunriseMs <= 0L && fajrMs <= 0L) {
                setViewVisibility(R.id.notif_footer, View.GONE)
            } else {
                setViewVisibility(R.id.notif_footer, View.VISIBLE)
            }
            setOnClickPendingIntent(
                R.id.notif_mute,
                PrayerScheduler.mutePendingIntent(context, id),
            )
            setOnClickPendingIntent(
                R.id.notif_dismiss,
                PrayerScheduler.dismissPendingIntent(context, id),
            )
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_mawaqit)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedViews)
            .setCustomBigContentView(views)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            Log.w(TAG, "Posting the $name reminder was refused by the system.")
        }
        PrayerScheduler.setAlarm(context, id, now + PrayerScheduler.TICK_MS, raw)
    }

    private fun showPrayerTimeNotification(
        context: Context,
        id: Int,
        channelId: String,
        name: String,
        prayerMs: Long,
    ) {
        val time = PrayerScheduler.timeLabel(prayerMs)
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_mawaqit)
            .setContentTitle(context.getString(R.string.notif_prayer_time, name))
            .setContentText(context.getString(R.string.notif_prayer_time_body, time))
            .setStyle(NotificationCompat.BigTextStyle())
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }
}
