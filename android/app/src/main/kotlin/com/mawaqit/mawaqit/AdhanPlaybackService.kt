package com.mawaqit.mawaqit

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaPlayer
import android.media.session.MediaSession
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that owns the Adhan audio. Started by [AdhanAlarmReceiver]
 * when an audible alarm fires (even with the Flutter process dead), it plays the
 * selected clip once through `MediaPlayer` on the alarm audio stream in a
 * sticky, system-owned foreground notification — the call rings until dismissed
 * or until the clip runs out, and finishing it tears the alarm down the same way
 * a dismissal does. Dismissal (volume keys, presenter Stop button, notification
 * Stop action, Flutter stop) funnels through [AdhanScheduler.stopActive].
 */
class AdhanPlaybackService : Service() {

    private var player: MediaPlayer? = null
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        AdhanScheduler.ensureChannels(this)
        ensureMediaSession()
    }

    /**
     * Android 15+ requires an active `MediaSession` to run a foreground
     * service of type `mediaPlayback` (the app targets SDK 36); without one
     * the system throws `MediaPlaybackServiceWithoutMediaSessionException` and
     * the whole process dies — no adhan, no full-screen alarm. A framework
     * session is enough to satisfy the check; playback stays on [MediaPlayer].
     */
    private fun ensureMediaSession() {
        if (mediaSession != null) return
        mediaSession = MediaSession(this, "mawaqit-adhan").apply {
            setCallback(object : MediaSession.Callback() {})
            setActive(true)
        }
    }

    private fun releaseMediaSession() {
        mediaSession?.apply {
            setActive(false)
            release()
        }
        mediaSession = null
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

    private fun startForegroundCompat(id: Int, schedule: AdhanScheduler.Schedule) {
        val notification = AdhanScheduler.buildAlarmNotification(
            this,
            schedule,
            mediaSession?.sessionToken,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // The typed overload can be rejected on the platform for reasons
            // that vary by release (media-session enforcement, OEM strictness).
            // Never let that crash the process: the full-screen alarm and the
            // ringing adhan must survive it, so fall back to the plain overload
            // (still a real foreground service, just without the declared type).
            try {
                startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } catch (e: Exception) {
                startForeground(id, notification)
            }
        } else {
            startForeground(id, notification)
        }
    }

    private fun startPlayback(schedule: AdhanScheduler.Schedule) {
        player?.release()
        // No resolvable audio (silent tone / missing device URI): the alarm is
        // already up — full-screen presenter + vibrating card — just stay quiet.
        val uri = AdhanScheduler.soundUri(this, schedule) ?: return
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
        } catch (_: Exception) {
            stopAdhan()
        }
    }

    override fun onDestroy() {
        releaseMediaSession()
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