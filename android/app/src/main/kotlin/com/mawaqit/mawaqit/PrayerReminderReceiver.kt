package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(PrayerScheduler.EXTRA_ID, -1)
        if (id == -1) return

        when (intent.action) {
            PrayerScheduler.ACTION_MUTE, PrayerScheduler.ACTION_DISMISS ->
                handleAction(context, id)
            else ->
                if (intent.action == PrayerScheduler.ACTION_SHOW) {
                    handleShow(context, id)
                }
        }
    }

    private fun handleAction(context: Context, id: Int) {
        PrayerScheduler.cancelAlarm(context, id)
        NotificationManagerCompat.from(context).cancel(id)
        PrayerScheduler.removePref(context, id)
    }

    private fun handleShow(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PrayerScheduler.PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString("reminder_$id", null) ?: return
        val data = JSONObject(raw)
        val name = data.getString(PrayerScheduler.EXTRA_NAME)
        val prayerMs = data.getLong(PrayerScheduler.EXTRA_PRAYER_MS)
        val leadMin = data.getInt(PrayerScheduler.EXTRA_LEAD_MIN)
        val now = System.currentTimeMillis()

        if (now >= prayerMs) {
            PrayerScheduler.cancelAlarm(context, id)
            PrayerScheduler.removePref(context, id)
            showPrayerTimeNotification(context, id, name, prayerMs)
            return
        }

        val leadStartMs = prayerMs - leadMin * 60_000L
        val totalMs = prayerMs - leadStartMs
        val elapsedMs = now - leadStartMs
        val percent = if (totalMs > 0) {
            (elapsedMs * 100 / totalMs).toInt().coerceIn(0, 100)
        } else {
            0
        }

        val remainingMin = ceil((prayerMs - now) / 60_000.0).toInt()
        val title = if (remainingMin >= 1) {
            "$name in ${remainingMin}${context.getString(R.string.notif_min_short)}"
        } else {
            context.getString(R.string.notif_now, name)
        }
        val time = PrayerScheduler.timeLabel(prayerMs)
        val sunriseMs = prefs.getLong(PrayerScheduler.KEY_SUNRISE, 0L)
        val fajrMs = prefs.getLong(PrayerScheduler.KEY_FAJR, 0L)

        val views = RemoteViews(context.packageName, R.layout.notification_prayer).apply {
            setTextViewText(R.id.notif_now, context.getString(R.string.notif_label_now))
            setTextViewText(R.id.notif_title, title)
            setTextViewText(
                R.id.notif_subtitle,
                context.getString(R.string.notif_subtitle, time),
            )
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

        val notification = NotificationCompat.Builder(context, PrayerScheduler.CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_stat_waqt)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(views)
            .setCustomBigContentView(views)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
        PrayerScheduler.setAlarm(context, id, now + PrayerScheduler.TICK_MS)
    }

    private fun showPrayerTimeNotification(
        context: Context,
        id: Int,
        name: String,
        prayerMs: Long,
    ) {
        val time = PrayerScheduler.timeLabel(prayerMs)
        val notification = NotificationCompat.Builder(context, PrayerScheduler.CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_stat_waqt)
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