package com.freesoftware.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Entry point for the pre-prayer live update.
 *
 * The one-minute tick and the initial post both arrive as [PrayerScheduler.ACTION_SHOW];
 * the two notification actions arrive as [PrayerScheduler.ACTION_PRAYED] and
 * [PrayerScheduler.ACTION_DISMISS]. The receiver owns no presentation itself —
 * it hands the payload to [PrayerLiveUpdate], which builds the promoted card.
 */
class PrayerReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(PrayerScheduler.EXTRA_ID, -1)
        if (id == -1) return

        when (intent.action) {
            PrayerScheduler.ACTION_PRAYED, PrayerScheduler.ACTION_DISMISS ->
                resolve(context, id)
            PrayerScheduler.ACTION_SHOW ->
                PrayerLiveUpdate.show(
                    context,
                    id,
                    intent.getStringExtra(PrayerScheduler.EXTRA_REMINDER),
                )
        }
    }

    /**
     * The user marked the prayer prayed or dismissed the card: drop the tick,
     * the stored payload and the notification, and remember the occurrence so a
     * later reschedule does not bring the card back.
     */
    private fun resolve(context: Context, id: Int) {
        PrayerScheduler.prayerId(context, id)?.let {
            PrayerLiveUpdate.markResolved(context, it)
        }
        PrayerScheduler.cancelAlarm(context, id)
        PrayerScheduler.removePref(context, id)
        PrayerLiveUpdate.cancel(context)
    }
}
