package com.mawaqit.mawaqit

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that owns the Adhan audio. Started by [AdhanAlarmReceiver]
 * when an audible alarm fires (even with the Flutter process dead), it loops the
 * selected clip through `MediaPlayer` on the alarm audio stream in a sticky,
 * system-owned foreground notification so the call keeps ringing until
 * dismissed. Dismissal (volume keys, activity Stop button, notification Stop
 * action, Flutter stop) funnels through [AdhanScheduler.stopActive].
 */
class AdhanPlaybackService : Service() {

    private var player: MediaPlayer? = null

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

        val name = intent.getStringExtra("name") ?: "Prayer"
        val raw = intent.getStringExtra("soundRaw").orEmpty()
        val uri = intent.getStringExtra("soundUri").orEmpty()
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
        val notification = AdhanScheduler.buildAlarmNotification(this, schedule)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(id, notification)
        }
    }

    private fun startPlayback(schedule: AdhanScheduler.Schedule) {
        player?.release()
        val uri = AdhanScheduler.soundUri(this, schedule) ?: run {
            stopSelf()
            return
        }
        try {
            val mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(AdhanScheduler.alarmAudioAttributes())
                setDataSource(this@AdhanPlaybackService, uri)
                isLooping = true
                setOnPreparedListener { it.start() }
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
        player?.release()
        player = null
        super.onDestroy()
    }

    /** Stops playback and tears down the alarm (also clears the activity via broadcast). */
    fun stopAdhan() {
        player?.stop()
        player = null
        AdhanScheduler.stopActive(this)
        stopSelf()
    }
}