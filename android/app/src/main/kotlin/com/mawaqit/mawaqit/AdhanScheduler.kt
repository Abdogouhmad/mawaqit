package com.mawaqit.mawaqit

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.util.Log
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

    /**
     * Full schedule snapshot embedded in the alarm [PendingIntent]. SharedPreferences
     * writes are asynchronous by default, so a user swiping the app away within
     * the schedule→fire window could leave the alarm with nothing to load; the
     * receiver falls back to this copy when prefs miss.
     */
    const val EXTRA_SCHEDULE = "com.mawaqit.extra.SCHEDULE_JSON"

    const val PREFS = "mawaqit_adhans"
    private const val KEY_NAME = "name"
    private const val KEY_PRAYER_ID = "prayer_id"
    private const val KEY_MUTED = "muted"
    private const val KEY_IS_TEST = "is_test"
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
        /** Debug test from Settings: always takes over the screen, even muted. */
        val isTest: Boolean = false,
    )

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun pendingIntent(context: Context, id: Int, scheduleJson: String? = null) =
        PendingIntent.getBroadcast(
            context,
            7000 + id, // distinct bucket from PrayerScheduler's 4000..6000
            Intent(context, AdhanAlarmReceiver::class.java)
                .setAction(ACTION_ADHAN)
                .putExtra(EXTRA_ID, id)
                .apply { if (scheduleJson != null) putExtra(EXTRA_SCHEDULE, scheduleJson) },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Content intent for the foreground-service card: reopen the app. */
    fun openAppPendingIntent(context: Context, id: Int) = PendingIntent.getActivity(
        context,
        7100 + id,
        context.packageManager.getLaunchIntentForPackage(context.packageName),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /**
     * Full-screen intent used by the alarm card. Android launches its target
     * itself (system-initiated), which is exempt from the background-activity
     * start restrictions that ban a naked `startActivity()` from a receiver
     * once the phone is locked or the app is killed — this is how the alarm
     * reliably wakes the display and presents over the lockscreen.
     */
    fun alarmActivityPendingIntent(context: Context, id: Int, name: String): PendingIntent =
        PendingIntent.getActivity(
            context,
            7300 + id,
            Intent(context, AdhanAlarmActivity::class.java)
                .setFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
                .putExtra(EXTRA_ID, id)
                .putExtra("name", name),
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
        isTest: Boolean = false,
    ) {
        val snapshot = JSONObject()
            .put(KEY_NAME, name)
            .put(KEY_PRAYER_ID, prayerId)
            .put(KEY_MUTED, muted)
            .put(KEY_IS_TEST, isTest)
            .put(KEY_SOUND_RAW, soundRaw)
            .put(KEY_SOUND_URI, soundUri)
            .put(KEY_TIMESTAMP, atEpochMs)
            .toString()

        // commit(), not apply(): the alarm can fire seconds later with the
        // process already swiped away, and the async disk write of apply()
        // may not have landed yet — the receiver would then find no snapshot.
        prefs(context).edit().putString("adhan_$id", snapshot).commit()

        // A near-past/now trigger (e.g. the 3-second debug test) must not be
        // pushed a minute into the future — only never schedule into the past.
        val trigger = maxOf(atEpochMs, System.currentTimeMillis())
        val am = alarmManager(context)
        val pi = pendingIntent(context, id, snapshot)
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
        return fromJson(id, raw)
    }

    /** Parses a schedule snapshot; used by [load] and the alarm-intent fallback. */
    fun fromJson(id: Int, raw: String?): Schedule? {
        if (raw.isNullOrBlank()) return null
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
            isTest = data.optBoolean(KEY_IS_TEST, false),
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
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
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
        mediaSessionToken: android.media.session.MediaSession.Token?,
    ): android.app.Notification {
        val stop = PendingIntent.getService(
            context,
            7200 + schedule.id,
            Intent(context, AdhanPlaybackService::class.java)
                .setAction(ACTION_STOP)
                .putExtra(EXTRA_ID, schedule.id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ALARM)
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
            .setFullScreenIntent(alarmActivityPendingIntent(context, schedule.id, schedule.name), true)
            .addAction(
                R.drawable.ic_close,
                "Stop",
                stop,
            )
        // Android 15+ mediaPlayback FGS enforcement accepts either an active
        // media session OR a notification carrying the MediaStyle session
        // token; some builds check only the token. Bind the live session to the
        // card so every release passes — otherwise the process can crash the
        // instant the alarm starts, killing the full-screen presenter before it
        // renders. Intent is a framework-only MediaStyle: `NotificationCompat`
        // refuses a framework style, so the freshly built card is re-wrapped
        // through `Notification.Builder.recoverBuilder` (API 24+, guarded).
        if (mediaSessionToken != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val replayed = Notification.Builder.recoverBuilder(context, builder.build())
            replayed.setStyle(
                Notification.MediaStyle().setMediaSession(mediaSessionToken),
            )
            return replayed.build()
        }
        return builder.build()
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
     *
     * A debug test ([Schedule.isTest]) always takes over the screen like a real
     * alarm — even when muted, it posts the full-screen card and simply stays
     * quiet — and it tears down any still-ringing alarm first, so re-tapping
     * "Test" always rings instead of being swallowed by the single-audio guard.
     */
    fun fireNow(context: Context, schedule: Schedule) {
        if (schedule.isTest) {
            stopActive(context)
        }
        // Single-audio guard: when the same occurrence is already ringing —
        // e.g. the AlarmManager fire raced the in-app rollover hand-off — the
        // earlier fire wins. Restarting here would double-ring the clip.
        if (isActive(context, schedule.id) && isPlaybackRunning(context)) {
            remove(context, schedule.id)
            return
        }
        remove(context, schedule.id)

        if (schedule.muted && !schedule.isTest) {
            postMutedCard(context, schedule)
            return
        }

        // A muted test demonstrates the full-screen alarm silently: drop any
        // resolved sound so the service mounts the card without audio.
        val effective = if (schedule.muted) {
            schedule.copy(soundRaw = "", soundUri = "")
        } else {
            schedule
        }

        markActive(context, effective.id)
        ensureChannels(context)

        // 1) System full-screen-intent card FIRST. Notifying with an alarm
        //    category + full-screen intent makes Android wake the display and
        //    launch [AdhanAlarmActivity] over the lockscreen itself — a
        //    system-initiated launch, so it is exempt from the background-
        //    activity start restrictions that swallow a naked startActivity
        //    from a receiver once the phone is locked / the app is killed.
        //    The service below re-posts the same id with the media-session
        //    style, replacing this card without re-alerting.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val nm = context.getSystemService(NotificationManager::class.java)
            if (nm != null && !nm.canUseFullScreenIntent()) {
                Log.w(
                    "AdhanScheduler",
                    "USE_FULL_SCREEN_INTENT denied — the lockscreen takeover " +
                        "degrades to a heads-up card until granted in Settings.",
                )
            }
        }
        try {
            NotificationManagerCompat.from(context)
                .notify(effective.id, buildAlarmNotification(context, effective, null))
        } catch (_: Exception) {
            // POST_NOTIFICATIONS denied / OEM strictness — the audio service
            // below still mounts the card through startForeground when it can.
        }

        // 2) The foreground service owns the audio. If its background start is
        //    rejected on a strict OEM build, the card (and its full-screen
        //    activity) above still takes over the screen — the call is simply
        //    silent in that degraded case.
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java)
            .putExtra(EXTRA_ID, effective.id)
            .putExtra("name", effective.name)
            .putExtra("soundRaw", effective.soundRaw)
            .putExtra("soundUri", effective.soundUri)
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {
            // Background FGS start denied — see comment above.
        }

        // 3) Foreground best-effort launch. When the app is on screen this is
        //    the instant path (SINGLE_TOP dedupes with the FSI launch); when it
        //    is not, the system FSI from step 1 already covers the takeover.
        val activityIntent = Intent(context, AdhanAlarmActivity::class.java)
            .setFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            .putExtra(EXTRA_ID, effective.id)
            .putExtra("name", effective.name)
        try {
            context.startActivity(activityIntent)
        } catch (_: Exception) {
            // Background activity launch denied — the FSI above handles it.
        }
    }
}