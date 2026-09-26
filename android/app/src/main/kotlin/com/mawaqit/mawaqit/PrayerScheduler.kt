package com.mawaqit.mawaqit

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Owns the exact-alarm reminders for the decorated prayer notification card. */
object PrayerScheduler {

    const val ACTION_SHOW = "com.mawaqit.action.SHOW_REMINDER"
    const val ACTION_MUTE = "com.mawaqit.action.MUTE_REMINDER"
    const val ACTION_DISMISS = "com.mawaqit.action.DISMISS_REMINDER"
    const val EXTRA_ID = "com.mawaqit.extra.ID"
    const val EXTRA_NAME = "com.mawaqit.extra.NAME"
    const val EXTRA_PRAYER_ID = "com.mawaqit.extra.PRAYER_ID"
    const val EXTRA_PRAYER_MS = "com.mawaqit.extra.PRAYER_MS"
    const val EXTRA_LEAD_MIN = "com.mawaqit.extra.LEAD_MIN"

    /** Channel (and its sound) the card for one reminder was armed with. */
    const val EXTRA_SOUND = "com.mawaqit.extra.SOUND"

    /**
     * Full reminder payload embedded in the alarm [android.app.PendingIntent].
     * SharedPreferences writes are asynchronous, so a user swiping the app away
     * right after a reschedule could leave the alarm with no stored entry — the
     * receiver then falls back to this copy instead of dropping the card.
     */
    const val EXTRA_REMINDER = "com.mawaqit.extra.REMINDER_JSON"

    // Base pre-prayer alert channel id. The concrete id is derived from the
    // selected tone's raw resource (see channelIdFor), so each tone gets a
    // freshly created, sound-correct channel — Android freezes a channel's
    // sound at first creation, so reusing one id across tone changes would
    // silently keep ringing the original tone. `_silent` covers the muted
    // pre-prayer preference.
    const val CHANNEL_REMINDERS = "pre_prayer_alert_v2"
    const val PREFS = "mawaqit_reminders"

    /** Ambient footer timestamps shown on the card (shared across that day). */
    const val KEY_SUNRISE = "info_sunrise"
    const val KEY_FAJR = "info_fajr"
    const val KEY_SUNSET = "info_sunset"
    const val KEY_CHANNEL_SOUND = "info_channel_sound"

    val TICK_MS = 60_000L
    // Distinct request-code buckets keep PendingIntents unique per purpose.
    private const val REQ_SHOW = 4000
    private const val REQ_MUTE = 5000
    private const val REQ_DISMISS = 6000

    private fun timeFormatter(): SimpleDateFormat =
        SimpleDateFormat("h:mm a", Locale.US)

    fun timeLabel(epochMs: Long): String = timeFormatter().format(Date(epochMs))

    fun channelIdFor(sound: String): String =
        if (sound == "silent") "${CHANNEL_REMINDERS}_silent" else "${CHANNEL_REMINDERS}_$sound"

    fun ensureReminderChannel(context: Context, sound: String = "pre_alert") {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelIdFor(sound),
                "Pre-prayer alert",
                if (sound == "silent") NotificationManager.IMPORTANCE_DEFAULT
                else NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Countdown reminder before each prayer"
                if (sound != "silent") {
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    setSound(Uri.parse("android.resource://${context.packageName}/raw/$sound"), audioAttributes)
                }
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    /** Schedules a daily reminder card for each prayer (lead time in the past). */
    fun schedule(
        context: Context,
        reminders: List<Map<String, Any>>,
        sunriseMs: Long = 0L,
        fajrMs: Long = 0L,
        sunsetMs: Long = 0L,
        channelSound: String = "pre_alert",
    ) {
        cancelAll(context)
        ensureReminderChannel(context, channelSound)

        val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        editor.putLong(KEY_SUNRISE, sunriseMs)
        editor.putLong(KEY_FAJR, fajrMs)
        editor.putLong(KEY_SUNSET, sunsetMs)
        editor.putString(KEY_CHANNEL_SOUND, channelSound)

        // Collect every entry, persist them all, and only then arm the alarms.
        // `commit()` (not `apply()`) on purpose: an alarm can fire with the
        // process already swiped away, and an entry that never reached disk is
        // a card that is silently never posted — the single most common way the
        // pre-prayer reminder used to go missing.
        val armed = mutableListOf<Triple<Int, Long, String>>()
        reminders.forEach { r ->
            val id = (r["id"] as? Number)?.toInt() ?: return@forEach
            val name = (r["name"] as? String) ?: "Prayer"
            val prayerId = (r["prayerId"] as? String) ?: ""
            val leadMs = (r["timestampMs"] as? Number)?.toLong() ?: 0L
            val prayerMs = (r["prayerTimestampMs"] as? Number)?.toLong() ?: 0L
            val leadMin = (r["leadMinutes"] as? Number)?.toInt() ?: 10

            val payload = JSONObject()
                .put(EXTRA_PRAYER_ID, prayerId)
                .put(EXTRA_NAME, name)
                .put(EXTRA_PRAYER_MS, prayerMs)
                .put(EXTRA_LEAD_MIN, leadMin)
                .put(EXTRA_SOUND, channelSound)
                .toString()
            editor.putString("reminder_$id", payload)
            armed += Triple(id, leadMs, payload)
        }
        editor.commit()
        armed.forEach { (id, leadMs, payload) -> setAlarm(context, id, leadMs, payload) }
    }

    fun cancelAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val keys = prefs.all.keys.filter { it.startsWith("reminder_") }
        keys.forEach { key ->
            val id = key.removePrefix("reminder_").toIntOrNull() ?: return@forEach
            am.cancel(showPendingIntent(context, id))
            NotificationManagerCompat.from(context).cancel(id)
        }
        prefs.edit().clear().apply()
    }

    fun setAlarm(context: Context, id: Int, atEpochMs: Long, payloadJson: String? = null) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = showPendingIntent(context, id, payloadJson)
        val trigger = maxOf(atEpochMs, System.currentTimeMillis() + TICK_MS)
        // Without the "Alarms & reminders" special access Android 12+ refuses
        // exact alarms outright; `setAndAllowWhileIdle` still fires, only
        // batched into the next maintenance window — a reminder the user may
        // only see minutes late, which is why the app asks for the access
        // (see [AlarmAccess.KEY_EXACT_ALARMS]) and shows it in Settings.
        if (AlarmAccess.canScheduleExactAlarms(context)) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        }
    }

    fun cancelAlarm(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(showPendingIntent(context, id))
    }

    /** Cancels one scheduled reminder: its alarm, its stored preferences and any
     *  card already posted. Used by the app to take over a reminder live
     *  (direct chime playback) without the native card also ringing. */
    fun cancelOne(context: Context, id: Int) {
        cancelAlarm(context, id)
        removePref(context, id)
        NotificationManagerCompat.from(context).cancel(id)
    }

    fun removePref(context: Context, id: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove("reminder_$id").apply()
    }

    fun showPendingIntent(context: Context, id: Int, payloadJson: String? = null) =
        PendingIntent.getBroadcast(
            context,
            REQ_SHOW + id,
            Intent(context, PrayerReminderReceiver::class.java)
                .setAction(ACTION_SHOW)
                .putExtra(EXTRA_ID, id)
                .apply { if (payloadJson != null) putExtra(EXTRA_REMINDER, payloadJson) },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun actionPendingIntent(
        context: Context,
        id: Int,
        action: String,
        base: Int,
    ): PendingIntent = PendingIntent.getBroadcast(
        context,
        base + id,
        Intent(context, PrayerReminderReceiver::class.java)
            .setAction(action)
            .putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** The occurrence id (`2026-09-21_maghrib`) backing the reminder card. */
    fun prayerId(context: Context, id: Int): String? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("reminder_$id", null) ?: return null
        return try {
            JSONObject(raw).optString(EXTRA_PRAYER_ID).takeIf { it.isNotBlank() }
        } catch (_: Exception) {
            null
        }
    }

    /** PendingIntent used by the [MutePrayerReceiver] lifecycle callback. */
    fun mutePendingIntent(context: Context, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REQ_MUTE + id,
            Intent(context, MutePrayerReceiver::class.java)
                .setAction(ACTION_MUTE)
                .putExtra(EXTRA_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun dismissPendingIntent(context: Context, id: Int): PendingIntent =
        actionPendingIntent(context, id, ACTION_DISMISS, REQ_DISMISS)
}