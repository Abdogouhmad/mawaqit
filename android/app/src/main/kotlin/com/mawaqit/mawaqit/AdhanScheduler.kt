package com.mawaqit.mawaqit

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * Owns the exact-alarm adhan "alarm clock" engine on Android.
 *
 * Flutter computes the prayer times and hands each occurrence over here; this
 * object persists the schedule, arms an exact `AlarmManager` alarm and, when it
 * fires, distributes the work to [AdhanAlarmReceiver] (foreground service that
 * owns the audio + a full-screen [AdhanAlarmActivity] over the lockscreen).
 * The audio is deliberately NOT the notification-channel sound — a dedicated
 * [AdhanPlaybackService] plays the selected clip through `MediaPlayer` on the
 * alarm stream, so the call rings even when the Flutter process is dead.
 */
object AdhanScheduler {

    const val ACTION_ADHAN = "com.mawaqit.action.ADHAN"
    const val ACTION_STOP = "com.mawaqit.action.STOP_ADHAN"
    const val EXTRA_ID = "com.mawaqit.extra.ADHAN_ID"

    const val PREFS = "mawaqit_adhans"
    private const val KEY_NAME = "name"
    private const val KEY_PRAYER_ID = "prayer_id"
    private const val KEY_MUTED = "muted"
    private const val KEY_SOUND_RAW = "sound_raw"
    private const val KEY_SOUND_URI = "sound_uri"
    private const val KEY_TIMESTAMP = "timestamp_ms"
    const val KEY_ACTIVE_ID = "active_adhan_id"

    /** Foreground-service channel: the app plays the clip itself, so no sound. */
    const val CHANNEL_ALARM = "prayer_adhan_alarm"

    /** Channel for a muted occurrence (silent card matching the Flutter default). */
    const val CHANNEL_SILENT = "prayer_adhan_silent_v2"

    /** Complete snapshot of one scheduled occurrence. */
    data class Schedule(
        val id: Int,
        val name: String,
        val prayerId: String,
        val muted: Boolean,
        val soundRaw: String,
        val soundUri: String,
        val timestampMs: Long,
    )

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun pendingIntent(context: Context, id: Int) =
        PendingIntent.getBroadcast(
            context,
            7000 + id, // distinct bucket from PrayerScheduler's 4000..6000
            Intent(context, AdhanAlarmReceiver::class.java)
                .setAction(ACTION_ADHAN)
                .putExtra(EXTRA_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Content intent for the foreground-service card: reopen the app. */
    fun openAppPendingIntent(context: Context, id: Int) = PendingIntent.getActivity(
        context,
        7100 + id,
        context.packageManager.getLaunchIntentForPackage(context.packageName),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Schedules (or replaces) one adhan occurrence at [atEpochMs]. */
    fun schedule(
        context: Context,
        id: Int,
        atEpochMs: Long,
        name: String,
        prayerId: String,
        muted: Boolean,
        soundRaw: String,
        soundUri: String,
    ) {
        prefs(context)
            .edit()
            .putString(
                "adhan_$id",
                JSONObject()
                    .put(KEY_NAME, name)
                    .put(KEY_PRAYER_ID, prayerId)
                    .put(KEY_MUTED, muted)
                    .put(KEY_SOUND_RAW, soundRaw)
                    .put(KEY_SOUND_URI, soundUri)
                    .put(KEY_TIMESTAMP, atEpochMs)
                    .toString(),
            )
            .apply()

        val trigger = maxOf(atEpochMs, System.currentTimeMillis() + 60_000L)
        val am = alarmManager(context)
        val pi = pendingIntent(context, id)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        }
    }

    fun cancel(context: Context, id: Int) {
        alarmManager(context).cancel(pendingIntent(context, id))
        prefs(context).edit().remove("adhan_$id").apply()
    }

    fun cancelAll(context: Context) {
        val stored = prefs(context).all.keys.filter { it.startsWith("adhan_") }
        stored.forEach { key ->
            val id = key.removePrefix("adhan_").toIntOrNull() ?: return@forEach
            alarmManager(context).cancel(pendingIntent(context, id))
        }
        prefs(context).edit().clear().apply()
    }

    /** Loads the stored snapshot for [id], or null when it no longer exists. */
    fun load(context: Context, id: Int): Schedule? {
        val raw = prefs(context).getString("adhan_$id", null) ?: return null
        val data = try {
            JSONObject(raw)
        } catch (_: Exception) {
            return null
        }
        return Schedule(
            id = id,
            name = data.optString(KEY_NAME, "Prayer"),
            prayerId = data.optString(KEY_PRAYER_ID, ""),
            muted = data.optBoolean(KEY_MUTED, false),
            soundRaw = data.optString(KEY_SOUND_RAW, ""),
            soundUri = data.optString(KEY_SOUND_URI, ""),
            timestampMs = data.optLong(KEY_TIMESTAMP, 0L),
        )
    }

    fun remove(context: Context, id: Int) {
        prefs(context).edit().remove("adhan_$id").apply()
    }

    /**
     * Centralized dismissal used by every route (volume keys, Stop button,
     * notification action, Flutter stop): silence the service, cancel the
     * alarm card and tell any live [AdhanAlarmActivity] to finish.
     */
    fun stopActive(context: Context) {
        context.stopService(Intent(context, AdhanPlaybackService::class.java))

        val activeId = prefs(context).getInt(KEY_ACTIVE_ID, -1)
        if (activeId != -1) {
            NotificationManagerCompat.from(context).cancel(activeId)
            prefs(context).edit().remove(KEY_ACTIVE_ID).apply()
        }

        context.sendBroadcast(
            Intent(ACTION_STOP).setPackage(context.packageName),
        )
    }

    /** Remembers the currently ringing occurrence while it lives. */
    fun markActive(context: Context, id: Int) {
        prefs(context).edit().putInt(KEY_ACTIVE_ID, id).apply()
    }

    fun isActive(context: Context, id: Int) =
        prefs(context).getInt(KEY_ACTIVE_ID, -1) == id

    /** Whether the adhan playback foreground service is currently up. */
    fun isPlaybackRunning(context: Context): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        return manager.getRunningServices(50).any {
            it.service.className == AdhanPlaybackService::class.java.name
        }
    }

    fun ensureChannels(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ALARM, "Prayer call (adhan)", NotificationManager.IMPORTANCE_HIGH)
                .apply {
                    description = "Plays the selected adhan at prayer entry"
                    setSound(null, null)
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 400, 200, 400, 200, 400)
                    setShowBadge(false)
                },
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_SILENT, "Prayer call (muted)", NotificationManager.IMPORTANCE_LOW)
                .apply {
                    description = "Adhan shown silently for a muted prayer occurrence"
                    setShowBadge(false)
                },
        )
    }

    /** Builds the loopable content URI for the selected sound. */
    fun soundUri(context: Context, schedule: Schedule): android.net.Uri? {
        if (schedule.soundUri.isNotBlank()) {
            return try {
                android.net.Uri.parse(schedule.soundUri)
            } catch (_: Exception) {
                null
            }
        }
        if (schedule.soundRaw.isNotBlank()) {
            return android.net.Uri.parse(
                "android.resource://${context.packageName}/raw/${schedule.soundRaw}",
            )
        }
        return null
    }

    /** Posts an on-going alarm card that routes dismissal through the service. */
    fun buildAlarmNotification(
        context: Context,
        schedule: Schedule,
    ): android.app.Notification {
        val stop = PendingIntent.getService(
            context,
            7200 + schedule.id,
            Intent(context, AdhanPlaybackService::class.java)
                .setAction(ACTION_STOP)
                .putExtra(EXTRA_ID, schedule.id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(context, CHANNEL_ALARM)
            .setSmallIcon(R.drawable.ic_stat_mawaqit)
            .setContentTitle("Adhan — ${schedule.name}")
            .setContentText("It is now time for the ${schedule.name} prayer")
            .setContentIntent(openAppPendingIntent(context, schedule.id))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setVibrate(longArrayOf(0, 400, 200, 400, 200, 400))
            .addAction(
                R.drawable.ic_close,
                "Stop",
                stop,
            )
            .build()
    }

    /** Silently posts the muted card for an occurrence (no audio, no takeover). */
    fun postMutedCard(context: Context, schedule: Schedule) {
        ensureChannels(context)
        NotificationManagerCompat.from(context).notify(
            schedule.id,
            NotificationCompat.Builder(context, CHANNEL_SILENT)
                .setSmallIcon(R.drawable.ic_stat_mawaqit)
                .setContentTitle("Adhan — ${schedule.name}")
                .setContentText("It is now time for the ${schedule.name} prayer")
                .setContentIntent(openAppPendingIntent(context, schedule.id))
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .build(),
        )
    }

    /** Yields the louder-than-reminder audio usage used by the alarm channel. */
    fun alarmAudioAttributes() = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    /**
     * Fires an occurrence immediately (muted → silent card; audible → foreground
     * [AdhanPlaybackService] + full-screen [AdhanAlarmActivity]). Shared by the
     * alarm-armed [AdhanAlarmReceiver] and the Flutter "test adhan" / live-rollover
     * hand-off so both paths behave identically.
     */
    fun fireNow(context: Context, schedule: Schedule) {
        // Single-audio guard: when the same occurrence is already ringing —
        // e.g. the AlarmManager fire raced the in-app rollover hand-off — the
        // earlier fire wins. Restarting here would double-ring the clip.
        if (isActive(context, schedule.id) && isPlaybackRunning(context)) {
            remove(context, schedule.id)
            return
        }
        remove(context, schedule.id)

        if (schedule.muted) {
            postMutedCard(context, schedule)
            return
        }

        markActive(context, schedule.id)

        val serviceIntent = Intent(context, AdhanPlaybackService::class.java)
            .putExtra(EXTRA_ID, schedule.id)
            .putExtra("name", schedule.name)
            .putExtra("soundRaw", schedule.soundRaw)
            .putExtra("soundUri", schedule.soundUri)
        ContextCompat.startForegroundService(context, serviceIntent)

        val activityIntent = Intent(context, AdhanAlarmActivity::class.java)
            .setFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            .putExtra(EXTRA_ID, schedule.id)
            .putExtra("name", schedule.name)
        context.startActivity(activityIntent)
    }
}