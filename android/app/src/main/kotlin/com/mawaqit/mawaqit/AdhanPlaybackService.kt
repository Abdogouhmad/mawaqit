package com.mawaqit.mawaqit

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * Foreground service that owns the Adhan audio. Started by [AdhanAlarmReceiver]
 * when an audible alarm fires (even with the Flutter process dead), it plays the
 * selected clip once through `MediaPlayer` on the alarm audio stream in a
 * sticky, system-owned foreground notification — the call rings until dismissed
 * or until the clip runs out, and finishing it tears the alarm down the same way
 * a dismissal does. Dismissal (volume keys, presenter Stop button, notification
 * Stop action, Flutter stop) funnels through [AdhanScheduler.stopActive].
 *
 * The service is declared `specialUse`, *not* `mediaPlayback`: a mediaPlayback
 * service is classified as music by the platform, so the adhan used to be
 * rendered as a media-player card (with a scrubber and playback controls, and
 * listed in the media output switcher) instead of as an alarm. Dropping the
 * type also drops the `MediaSession` that Android 15+ demanded for a media
 * playback service, along with the crash risk that came with it.
 */
class AdhanPlaybackService : Service() {

    private var player: MediaPlayer? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var maxDurationRunnable: Runnable? = null

    /** Generous ceiling; a real adhan is a few minutes. See [armMaxDuration]. */
    private companion object {
        const val MAX_DURATION_MS = 10L * 60L * 1000L
    }

    override fun onCreate() {
        super.onCreate()
        AdhanScheduler.ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getIntExtra(AdhanScheduler.EXTRA_ID, -1) ?: -1
        val stop = intent?.action == AdhanScheduler.ACTION_STOP

        if (stop || id == -1) {
            if (stop) AdhanScheduler.stopActive(this)
            stopSelf()
            return START_NOT_STICKY
        }

        val name = intent?.getStringExtra("name") ?: "Prayer"
        val raw = intent?.getStringExtra("soundRaw").orEmpty()
        val uri = intent?.getStringExtra("soundUri").orEmpty()
        val schedule = AdhanScheduler.Schedule(
            id = id,
            name = name,
            prayerId = "",
            muted = false,
            soundRaw = raw,
            soundUri = uri,
            timestampMs = System.currentTimeMillis(),
        )

        AdhanScheduler.markActive(this, id)
        startForegroundCompat(id, schedule)
        startPlayback(schedule)
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Mounts the alarm card. The *same* card carries the full-screen intent, so
     * there is exactly one notification for a ringing adhan: it used to be
     * posted twice under one id — once with the full-screen intent and once
     * from `startForeground` — so the media-style card replaced the full-screen
     * one within milliseconds of it being posted.
     */
    private fun startForegroundCompat(id: Int, schedule: AdhanScheduler.Schedule) {
        val notification = AdhanScheduler.buildAlarmNotification(this, schedule)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // The typed overload can be rejected on the platform for reasons
            // that vary by release (OEM strictness). Never let that crash the
            // process: the full-screen alarm and the ringing adhan must survive
            // it, so fall back to the plain overload (still a real foreground
            // service, just without the declared type). Below Android 14 the
            // `specialUse` type does not exist yet and must not be passed.
            try {
                startForeground(
                    id,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } catch (_: Exception) {
                startForeground(id, notification)
            }
        } else {
            startForeground(id, notification)
        }
    }

    private fun startPlayback(schedule: AdhanScheduler.Schedule) {
        player?.release()
        // No resolvable audio (silent tone / missing device URI). This used to
        // `return` with the alarm already up — foreground service, full-screen
        // presenter and the Do Not Disturb lift all engaged — and nothing left
        // to ever tear them down: with no MediaPlayer there is no completion and
        // no error callback. That is an orphan alarm that holds the lockscreen
        // and keeps forcing DND off until the user dismissed it by hand.
        // Dart now routes every known-unplayable source to a quiet Flutter card
        // instead of arming native at all, so this is the last-resort backstop:
        // treat it exactly like a playback error and tear the alarm down.
        val uri = AdhanScheduler.soundUri(this, schedule) ?: run {
            stopAdhan()
            return
        }
        try {
            val mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(AdhanScheduler.alarmAudioAttributes())
                setDataSource(this@AdhanPlaybackService, uri)
                // One pass, never a loop: when the clip ends the alarm stops
                // itself (service, tray card and presenter go down together).
                isLooping = false
                setOnPreparedListener { it.start() }
                setOnCompletionListener {
                    stopAdhan()
                }
                setOnErrorListener { _, _, _ ->
                    stopAdhan()
                    true
                }
                prepareAsync()
            }
            player = mediaPlayer
            armMaxDuration()
        } catch (_: Exception) {
            stopAdhan()
        }
    }

    /**
     * Ceiling on how long one alarm may hold the service, the presenter and the
     * DND lift. A normal adhan reports completion in a few minutes, so this only
     * ever fires when that report never comes — a device tone backed by a live
     * stream, a source the platform accepted but never decoded. The Dart
     * watchdog in `NotificationService` cannot cover this: when an alarm is
     * fired with the Flutter process dead there is no Dart isolate to run it.
     */
    private fun armMaxDuration() {
        cancelMaxDuration()
        maxDurationRunnable = Runnable { stopAdhan() }
        mainHandler.postDelayed(maxDurationRunnable, MAX_DURATION_MS)
    }

    private fun cancelMaxDuration() {
        maxDurationRunnable?.let { mainHandler.removeCallbacks(it) }
        maxDurationRunnable = null
    }

    override fun onDestroy() {
        cancelMaxDuration()
        player?.release()
        player = null
        // Backstop: every dismissal already restores the interruption filter
        // through AdhanScheduler.stopActive, but a torn-down process must never
        // leave the phone in "alarms only" either.
        AlarmAccess.restoreDndFilter(this)
        super.onDestroy()
    }

    /** Stops playback and tears down the alarm (also clears the presenter via broadcast). */
    fun stopAdhan() {
        cancelMaxDuration()
        try {
            // release() is valid in every player state — unlike stop(), it can
            // never throw while prepareAsync is still in flight — and it frees
            // the native MediaPlayer instead of just dropping the reference.
            player?.release()
        } catch (_: Exception) {
            // Already released — nothing to do; onDestroy is a no-op then.
        }
        player = null
        AdhanScheduler.stopActive(this)
        stopSelf()
    }
}
