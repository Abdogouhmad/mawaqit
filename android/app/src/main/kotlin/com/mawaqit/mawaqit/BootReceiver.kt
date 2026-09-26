package com.mawaqit.mawaqit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Re-arms today's adhans and reminders after the phone restarts, or after the
 * app is updated in place.
 *
 * `AlarmManager` drops every alarm it is holding when the package is replaced,
 * so both of these leave the day unarmed: a reboot clears them outright, and an
 * OTA update (this app ships its own updater) replaces the package and takes
 * them with it. Nothing re-arms them until the next 12-hourly WorkManager task,
 * which can be most of a day away — a phone that restarted at breakfast can
 * reach Isha with no adhan scheduled at all, and an update can silently cost
 * the user the rest of the day.
 *
 * The re-arm itself needs today's prayer times, which only the Dart side can
 * compute (it owns the location cache, the calculation method and the user's
 * settings), so the work is handed to a one-time WorkManager task. Handing it to
 * WorkManager rather than starting a foreground service matters on Android 15+,
 * where a `BOOT_COMPLETED` receiver may not launch several foreground-service
 * types at all.
 *
 * Both actions are post-unlock, so the credential-protected stores this and
 * [AdhanScheduler] read are available; `LOCKED_BOOT_COMPLETED` is deliberately
 * not handled.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }

        // Fail quietly: a reboot with no re-arm degrades to the 12-hourly task
        // rather than crashing the receiver, which would only hide the cause.
        try {
            BootRescheduleWork.enqueue(context)
        } catch (e: Exception) {
            Log.w("BootReceiver", "Could not queue the post-$action re-arm: $e")
        }

    }
}
