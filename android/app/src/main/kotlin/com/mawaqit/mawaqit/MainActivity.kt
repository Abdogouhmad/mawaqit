package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var previewRingtone: Ringtone? = null
    private var channel: MethodChannel? = null
    private var alarmActive = false

    /** Occurrence the native engine wants presented (until Flutter consumes it). */
    private var pendingAdhanId: Int = -1
    private var pendingAdhanName: String? = null

    /**
     * The alarm stopped on the native side (clip finished, tray Stop action):
     * drop the lockscreen takeover and tell Flutter so its presenter closes.
     */
    private val alarmStopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != AdhanScheduler.ACTION_STOP) return
            val id = intent.getIntExtra(AdhanScheduler.EXTRA_ID, -1)
            alarmActive = false
            pendingAdhanId = -1
            pendingAdhanName = null
            clearAlarmPresentation()
            try {
                channel?.invokeMethod("alarmStopped", mapOf("id" to id))
            } catch (_: Exception) {
                // Flutter side not attached — nothing to notify.
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(AdhanScheduler.ACTION_STOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(alarmStopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(alarmStopReceiver, filter)
        }
        handleAdhanIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAdhanIntent(intent)
    }

    /**
     * The engine launched this shell with a ringing occurrence (full-screen
     * intent or alarm-card tap): take over the lockscreen immediately and stash
     * the occurrence until Flutter consumes it and raises the presenter.
     */
    private fun handleAdhanIntent(intent: Intent?) {
        if (intent?.action != AdhanScheduler.ACTION_SHOW_ADHAN) return
        val id = intent.getIntExtra(AdhanScheduler.EXTRA_ID, -1)
        if (id == -1) return
        pendingAdhanId = id
        pendingAdhanName = intent.getStringExtra(AdhanScheduler.EXTRA_NAME) ?: "Prayer"
        alarmActive = true
        applyAlarmPresentation()
        notifyFlutterAdhan()
    }

    /** The alarm presenter may sit over the lockscreen and must keep the screen on. */
    private fun applyAlarmPresentation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun clearAlarmPresentation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun notifyFlutterAdhan() {
        try {
            channel?.invokeMethod("adhanFired", null)
        } catch (_: Exception) {
            // Flutter handler not attached yet — init() pulls the stashed
            // occurrence itself, so nothing is lost.
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Inside the MethodChannel's `.apply {}` receiver below, `this` is the
        // channel — so keep the Activity context here for PrayerScheduler calls.
        val activity = this
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mawaqit/native",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAlarmActive" -> {
                        alarmActive = call.argument<Boolean>("active") ?: false
                        if (alarmActive) {
                            applyAlarmPresentation()
                        } else {
                            clearAlarmPresentation()
                        }
                        result.success(true)
                    }
                    "consumePendingAdhan" -> {
                        val name = pendingAdhanName
                        val id = pendingAdhanId
                        if (name != null && id != -1) {
                            pendingAdhanName = null
                            pendingAdhanId = -1
                            result.success(mapOf("name" to name, "id" to id))
                        } else {
                            result.success(null)
                        }
                    }
                    "scheduleReminders" -> {
                        val reminders =
                            call.argument<List<Map<String, Any>>>("reminders") ?: emptyList()
                        val sunriseMs = call.argument<Number>("sunriseMs")?.toLong() ?: 0L
                        val fajrMs = call.argument<Number>("fajrMs")?.toLong() ?: 0L
                        val sunsetMs = call.argument<Number>("sunsetMs")?.toLong() ?: 0L
                        val channelSound = call.argument<String>("channelSound") ?: "silent"
                        PrayerScheduler.schedule(activity, reminders, sunriseMs, fajrMs, sunsetMs, channelSound)
                        result.success(true)
                    }
                    "cancelReminders" -> {
                        PrayerScheduler.cancelAll(activity)
                        result.success(true)
                    }
                    "cancelReminder" -> {
                        val id = call.argument<Number>("id")?.toInt() ?: -1
                        if (id >= 0) PrayerScheduler.cancelOne(activity, id)
                        result.success(true)
                    }
                    "listDeviceTones" -> result.success(listDeviceTones())
                    "previewDeviceTone" -> {
                        val uri = call.argument<String>("uri")
                        result.success(previewDeviceTone(uri))
                    }
                    "stopDeviceTonePreview" -> {
                        stopDeviceTonePreview()
                        result.success(true)
                    }
                    "scheduleAdhan" -> {
                        val id = call.argument<Number>("id")?.toInt() ?: -1
                        val timestampMs = call.argument<Number>("timestampMs")?.toLong() ?: 0L
                        val name = call.argument<String>("name") ?: "Prayer"
                        val prayerId = call.argument<String>("prayerId") ?: ""
                        val muted = call.argument<Boolean>("muted") ?: false
                        val soundRaw = call.argument<String>("soundRaw") ?: ""
                        val soundUri = call.argument<String>("soundUri") ?: ""
                        val isTest = call.argument<Boolean>("isTest") ?: false
                        if (id != -1) {
                            AdhanScheduler.schedule(
                                context = activity,
                                id = id,
                                atEpochMs = timestampMs,
                                name = name,
                                prayerId = prayerId,
                                muted = muted,
                                soundRaw = soundRaw,
                                soundUri = soundUri,
                                isTest = isTest,
                            )
                        }
                        result.success(true)
                    }
                    "cancelAdhan" -> {
                        val id = call.argument<Number>("id")?.toInt() ?: -1
                        if (id >= 0) AdhanScheduler.cancel(activity, id)
                        result.success(true)
                    }
                    "cancelAdhans" -> {
                        AdhanScheduler.cancelAll(activity)
                        result.success(true)
                    }
                    "stopAdhan" -> {
                        AdhanScheduler.stopActive(activity)
                        result.success(true)
                    }
                    "fireAdhanNow" -> {
                        val id = call.argument<Number>("id")?.toInt() ?: -1
                        val name = call.argument<String>("name") ?: "Prayer"
                        val muted = call.argument<Boolean>("muted") ?: false
                        val soundRaw = call.argument<String>("soundRaw") ?: ""
                        val soundUri = call.argument<String>("soundUri") ?: ""
                        val isTest = call.argument<Boolean>("isTest") ?: false
                        if (id != -1) {
                            AdhanScheduler.fireNow(
                                activity,
                                AdhanScheduler.Schedule(
                                    id = id,
                                    name = name,
                                    prayerId = "",
                                    muted = muted,
                                    soundRaw = soundRaw,
                                    soundUri = soundUri,
                                    timestampMs = System.currentTimeMillis(),
                                    isTest = isTest,
                                ),
                            )
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        // Cold start raced ahead of the channel: if the engine was launched by
        // a ringing occurrence, ping Flutter now that both handlers are up.
        if (pendingAdhanId != -1) {
            notifyFlutterAdhan()
        }
    }

    /**
     * While an adhan alarm is ringing the volume/side buttons stop it instead
     * of changing the stream volume — standard alarm-stop behaviour. The press
     * is consumed here and forwarded to Flutter so the app can stop playback,
     * clear the tray notification and close the full-screen presenter.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (alarmActive && isVolumeKey(keyCode)) return true
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (alarmActive && isVolumeKey(keyCode)) {
            channel?.invokeMethod("alarmDismissRequest", null)
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun isVolumeKey(keyCode: Int): Boolean =
        keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN

    override fun onDestroy() {
        stopDeviceTonePreview()
        try {
            unregisterReceiver(alarmStopReceiver)
        } catch (_: Exception) {
            // Already unregistered — nothing to do.
        }
        channel = null
        super.onDestroy()
    }

    /** Collects notification, alarm and ringtone sounds already on the device. */
    private fun listDeviceTones(): List<Map<String, String>> {
        val tones = LinkedHashMap<String, String>()
        val types = listOf(
            RingtoneManager.TYPE_NOTIFICATION,
            RingtoneManager.TYPE_ALARM,
            RingtoneManager.TYPE_RINGTONE,
        )
        for (type in types) {
            try {
                val manager = RingtoneManager(this)
                manager.setType(type)
                val cursor = manager.cursor ?: continue
                var index = 0
                while (cursor.moveToNext() && index < 200) {
                    val uri = manager.getRingtoneUri(index)?.toString()
                    if (uri != null && !tones.containsKey(uri)) {
                        val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                        tones[uri] = title?.trim().takeUnless { it.isNullOrEmpty() }
                            ?: "Device sound"
                    }
                    index++
                }
            } catch (_: Exception) {
                // Skip a category that isn't readable on this device.
            }
        }
        return tones.map { (uri, title) -> mapOf("name" to title, "uri" to uri) }
    }

    private fun previewDeviceTone(uriString: String?): Boolean {
        if (uriString.isNullOrEmpty()) return false
        stopDeviceTonePreview()
        return try {
            val ringtone = RingtoneManager.getRingtone(this, Uri.parse(uriString))
            ringtone?.play()
            previewRingtone = ringtone
            ringtone != null
        } catch (_: Exception) {
            false
        }
    }

    private fun stopDeviceTonePreview() {
        try {
            previewRingtone?.stop()
        } catch (_: Exception) {
        } finally {
            previewRingtone = null
        }
    }
}
