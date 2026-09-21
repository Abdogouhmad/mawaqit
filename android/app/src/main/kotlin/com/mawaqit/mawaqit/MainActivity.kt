package com.mawaqit.mawaqit

import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var previewRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mawaqit/native",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleReminders" -> {
                    val reminders =
                        call.argument<List<Map<String, Any>>>("reminders") ?: emptyList()
                    val sunriseMs = call.argument<Number>("sunriseMs")?.toLong() ?: 0L
                    val fajrMs = call.argument<Number>("fajrMs")?.toLong() ?: 0L
                    val sunsetMs = call.argument<Number>("sunsetMs")?.toLong() ?: 0L
                    val channelSound = call.argument<String>("channelSound") ?: "silent"
                    PrayerScheduler.schedule(this, reminders, sunriseMs, fajrMs, sunsetMs, channelSound)
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
                        context = this,
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
                    PrayerScheduler.cancelAll(this)
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
                else -> result.notImplemented()
            }
        }
    }

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
