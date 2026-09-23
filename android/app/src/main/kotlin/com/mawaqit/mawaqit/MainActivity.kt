package com.mawaqit.mawaqit

import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var previewRingtone: Ringtone? = null
    private var channel: MethodChannel? = null
    private var alarmActive = false

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
                        result.success(true)
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
                    "showTestReminder" -> {
                        val id = call.argument<Number>("id")?.toInt() ?: 1_999_999
                        val name = call.argument<String>("name") ?: "Maghrib"
                        val prayerId = call.argument<String>("prayerId") ?: "test_maghrib"
                        val leadMinutes = call.argument<Number>("leadMinutes")?.toInt() ?: 10
                        val prayerMs = call.argument<Number>("prayerTimestampMs")?.toLong() ?: 0L
                        val sunriseMs = call.argument<Number>("sunriseMs")?.toLong() ?: 0L
                        val fajrMs = call.argument<Number>("fajrMs")?.toLong() ?: 0L
                        val sunsetMs = call.argument<Number>("sunsetMs")?.toLong() ?: 0L
                        val channelSound = call.argument<String>("channelSound") ?: "silent"
                        PrayerScheduler.showTestReminder(
                            context = activity,
                            id = id,
                            name = name,
                            prayerId = prayerId,
                            leadMinutes = leadMinutes,
                            prayerMs = prayerMs,
                            sunriseMs = sunriseMs,
                            fajrMs = fajrMs,
                            sunsetMs = sunsetMs,
                            channelSound = channelSound,
                        )
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
                                ),
                            )
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
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
        super.onDestroy()
    }

    /// Collects notification, alarm and ringtone sounds already on the device.
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
