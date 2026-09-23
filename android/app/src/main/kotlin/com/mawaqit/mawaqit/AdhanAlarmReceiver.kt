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

        val schedule = AdhanScheduler.load(context, id) ?: return
        AdhanScheduler.fireNow(context, schedule)
    }
}