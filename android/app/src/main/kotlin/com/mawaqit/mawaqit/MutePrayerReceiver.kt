package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat

/**
 * FIX 5: marks one prayer occurrence as muted from the lockscreen card, then
 * clears the card and its pending alarm.
 *
 * The flag is written straight into the file used by Flutter's
 * `shared_preferences` plugin (`FlutterSharedPreferences`, keys prefixed with
 * `flutter.`), so the Dart side sees the mute immediately on next app open
 * without any method-channel round-trip.
 */
class MutePrayerReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(PrayerScheduler.EXTRA_ID, -1)
        if (id == -1) return

        val prayerId = PrayerScheduler.prayerId(context, id)
        if (prayerId != null) {
            context
                .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("flutter.muted_prayer_$prayerId", true)
                .commit()
        }

        PrayerScheduler.cancelAlarm(context, id)
        NotificationManagerCompat.from(context).cancel(id)
        PrayerScheduler.removePref(context, id)
    }
}