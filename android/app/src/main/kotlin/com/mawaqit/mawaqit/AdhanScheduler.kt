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
 * fires, distributes the work to [AdhanAlarmReceiver]: a [AdhanPlaybackService]
 * that owns the audio *and* mounts the single alarm card, whose full-screen
 * intent makes the system raise the shell's in-app presenter. The audio is
 * deliberately NOT the notification-channel sound — the service plays the
 * selected clip through `MediaPlayer` on the alarm stream, so the call rings
 * even when the Flutter process is dead.
 *
 * The takeover has two halves, because the platform only ever allows one of
 * them at a time: a locked (or off) screen is handed to the system through
 * the card's full-screen intent, while an unlocked screen — where a full-screen
 * intent is deliberately downgraded to a heads-up card — depends on
 * [forceShowAdhan]. See [AlarmAccess] for the accesses both need.
 */
object AdhanScheduler {

    const val ACTION_ADHAN = "com.mawaqit.action.ADHAN"
    const val ACTION_STOP = "com.mawaqit.action.STOP_ADHAN"

    /** Launches the shell and tells it to raise the in-app adhan presenter. */
    const val ACTION_SHOW_ADHAN = "com.mawaqit.action.SHOW_ADHAN"
    const val EXTRA_ID = "com.mawaqit.extra.ADHAN_ID"
    const val EXTRA_NAME = "com.mawaqit.extra.ADHAN_NAME"

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

    /**
     * Content intent for the foreground-service card: reopen the app, raising
     * the presenter when the alarm is still ringing ([name] given), plain home
     * otherwise (muted card).
     */
    fun openAppPendingIntent(context: Context, id: Int, name: String? = null) = PendingIntent.getActivity(
        context,
        7100 + id,
        if (name != null) {
            showAdhanIntent(context, id, name)
        } else {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /**
     * Intent that raises the shell's own full-screen adhan presenter
     * ([MainActivity] → `AdhanOverlayScreen` in Flutter).
     *
     * `REORDER_TO_FRONT` matters for [forceShowAdhan]: when Mawaqit is alive in
     * the background, the existing task is brought forward with its Flutter
     * engine and navigation state intact instead of being rebuilt.
     */
    fun showAdhanIntent(context: Context, id: Int, name: String): Intent =
        Intent(context, MainActivity::class.java)
            .setAction(ACTION_SHOW_ADHAN)
            .setFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            .putExtra(EXTRA_ID, id)
            .putExtra(EXTRA_NAME, name)

    /**
     * Full-screen intent used by the alarm card. Android launches its target
     * itself (system-initiated), which is exempt from the background-activity
     * start restrictions that ban a naked `startActivity()` from a receiver
     * once the phone is locked or the app is killed — this is how the alarm
     * reliably wakes the display and presents over the lockscreen.
     *
     * The system only *launches* it while the screen is locked, off, or on
     * always-on display; on an unlocked screen it downgrades the notification
     * to a persistent heads-up card no matter how the alarm is configured.
     * That case is [forceShowAdhan]'s job.
     */
    fun alarmActivityPendingIntent(context: Context, id: Int, name: String): PendingIntent =
        PendingIntent.getActivity(
            context,
            7300 + id,
            showAdhanIntent(context, id, name),
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
        if (AlarmAccess.canScheduleExactAlarms(context)) {
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
     * alarm card and tell the shell's live presenter to close.
     *
     * [notifyFlutter] is false for a teardown that is immediately followed by
     * a fresh fire (the debug test re-arming itself): the old presenter is
     * replaced by the new one anyway, and forwarding the stale stop would let
     * it knock down the alarm that just replaced it.
     */
    fun stopActive(context: Context, notifyFlutter: Boolean = true) {
        context.stopService(Intent(context, AdhanPlaybackService::class.java))

        // The call is over, so the phone goes back to the interruption mode the
        // user had chosen (see [AlarmAccess.forceAdhanThroughDnd]).
        AlarmAccess.restoreDndFilter(context)

        val activeId = prefs(context).getInt(KEY_ACTIVE_ID, -1)
        if (activeId != -1) {
            NotificationManagerCompat.from(context).cancel(activeId)
            prefs(context).edit().remove(KEY_ACTIVE_ID).apply()
        }

        if (notifyFlutter) {
            context.sendBroadcast(
                Intent(ACTION_STOP)
                    .setPackage(context.packageName)
                    .putExtra(EXTRA_ID, activeId),
            )
        }
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

    /** Builds the content URI for the selected sound. */
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

    /**
     * The one card for a ringing adhan: an on-going alarm notification that
     * carries the full-screen intent, so the system both wakes the display and
     * launches the presenter (locked / off / AOD) and shows a stoppable
     * heads-up card (unlocked).
     *
     * Deliberately no `MediaStyle` and no media session: a media-style card is
     * what made the adhan look like a music player, with a scrubber and
     * playback controls, in the shade and on the lockscreen.
     */
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
            .setContentIntent(openAppPendingIntent(context, schedule.id, schedule.name))
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
            .build()
    }

    /**
     * Fallback for when the playback service cannot be started from the
     * background: mounts the same card (full-screen intent included) directly,
     * so the takeover still happens and only the audio is lost.
     */
    fun postAlarmCard(context: Context, schedule: Schedule) {
        ensureChannels(context)
        try {
            NotificationManagerCompat.from(context)
                .notify(schedule.id, buildAlarmNotification(context, schedule))
        } catch (_: Exception) {
            // POST_NOTIFICATIONS denied / OEM strictness — nothing to show.
        }
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

    /**
     * Yields the louder-than-reminder audio usage used by the alarm channel.
     *
     * `CONTENT_TYPE_SONIFICATION` rather than `CONTENT_TYPE_MUSIC`: the routing
     * is decided by `USAGE_ALARM` either way, but music content type is what
     * asks the platform's media stack to treat the clip as a track rather than
     * as an alarm call.
     */
    fun alarmAudioAttributes() = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    /**
     * Puts the adhan presenter on screen.
     *
     * A full-screen intent is *not* enough once the phone is unlocked: Android
     * refuses to launch one and downgrades the card to a heads-up notification,
     * deliberately, so an alarm cannot hijack a screen the user is already
     * using. The presenter is an ordinary activity, so bringing it up from a
     * background receiver is a background-activity launch, which Android 10+
     * blocks whenever another app is in the foreground.
     *
     * This is a no-throw best effort across the three cases that matter:
     *  - Mawaqit is on screen → allowed outright, the presenter opens at once.
     *  - "Display over other apps" is granted ([AlarmAccess.canDrawOverlays])
     *    → the one user-grantable exemption from the restriction, so the
     *      presenter takes the screen from whatever the user was doing.
     *  - Otherwise → silently blocked by the platform, and the heads-up card
     *    with its Stop action is all the user gets. Nothing is lost but the
     *    takeover, so the failure is logged rather than surfaced.
     */
    fun forceShowAdhan(context: Context, schedule: Schedule) {
        try {
            context.startActivity(showAdhanIntent(context, schedule.id, schedule.name))
        } catch (e: Exception) {
            val hint = if (AlarmAccess.canDrawOverlays(context)) {
                ""
            } else {
                " — grant \"Display over other apps\" in Settings → Alarm " +
                    "reliability to force the full screen while the phone is in use."
            }
            Log.w(
                "AdhanScheduler",
                "Adhan presenter could not be raised " +
                    "(${e.javaClass.simpleName})$hint",
            )
        }
    }

    /**
     * Fires an occurrence immediately (muted → silent card; audible → foreground
     * [AdhanPlaybackService] + the shell's full-screen presenter). Shared by the
     * alarm-armed [AdhanAlarmReceiver] and the Flutter "test adhan" / live-rollover
     * hand-off so both paths behave identically.
     *
     * A debug test ([Schedule.isTest]) always takes over the screen like a real
     * alarm — even when muted, it posts the full-screen card and simply stays
     * quiet — and it tears down any still-ringing alarm first (silently: the
     * fresh fire replaces that presenter itself), so re-tapping "Test" always
     * rings instead of being swallowed by the single-audio guard.
     */
    fun fireNow(context: Context, schedule: Schedule) {
        if (schedule.isTest) {
            stopActive(context, notifyFlutter = false)
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

        // "Force the adhan": with Do Not Disturb access granted, silent mode is
        // lifted to "alarms only" for the duration of the call, so a phone that
        // is silenced (or in DND) still rings the adhan at prayer time. Restored
        // by [stopActive] on every teardown path.
        AlarmAccess.forceAdhanThroughDnd(context)

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

        // 1) The foreground service owns both the audio *and* the one card for
        //    this occurrence. The card carries the full-screen intent, so the
        //    system itself wakes the display and launches the presenter while
        //    the phone is locked, off, or on always-on display — a
        //    system-initiated launch, exempt from the background-activity start
        //    restrictions that ban a receiver from doing it itself.
        //
        //    There is deliberately no separate pre-posted card: it used to be
        //    notified first under this same id and then replaced by the
        //    service's `startForeground` a few milliseconds later, which threw
        //    the full-screen intent away before the system could act on it and
        //    left the user looking at a second, media-player-looking card.
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java)
            .putExtra(EXTRA_ID, effective.id)
            .putExtra("name", effective.name)
            .putExtra("soundRaw", effective.soundRaw)
            .putExtra("soundUri", effective.soundUri)
        var serviceStarted = true
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {
            // Background FGS start denied on a strict OEM build: no audio, but
            // the takeover is still worth having.
            serviceStarted = false
        }
        if (!serviceStarted) {
            postAlarmCard(context, effective)
        }

        // 2) Takeover on an *unlocked* screen, which a full-screen intent
        //    never does. Covers Mawaqit being in the foreground (immediate) and
        //    "Display over other apps" being granted (exempt from the
        //    background-activity-launch restriction); otherwise the heads-up
        //    card is all the platform allows.
        forceShowAdhan(context, effective)
    }
}
