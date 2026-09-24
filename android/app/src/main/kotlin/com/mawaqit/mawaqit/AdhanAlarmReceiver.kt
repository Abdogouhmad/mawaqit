package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Alarm fire for an adhan occurrence. This is the whole point of the native
 * engine: it runs in a plain `BroadcastReceiver` (no Flutter engine needed), so
 * it works when the app process is dead or the phone is locked and asleep. All
 * real work is delegated to [AdhanScheduler.fireNow].
 */
class AdhanAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != AdhanScheduler.ACTION_ADHAN) return
        val id = intent.getIntExtra(AdhanScheduler.EXTRA_ID, -1)
        if (id == -1) return

        // Prefs first (normal path); the alarm intent carries the same
        // snapshot so a fire still works when the process was swiped away
        // before the prefs write reached disk.
        val schedule = AdhanScheduler.load(context, id)
            ?: AdhanScheduler.fromJson(
                id,
                intent.getStringExtra(AdhanScheduler.EXTRA_SCHEDULE),
            )
            ?: return
        AdhanScheduler.fireNow(context, schedule)
    }
}