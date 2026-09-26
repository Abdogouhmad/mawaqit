package com.mawaqit.mawaqit

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker

/**
 * Queues the one-time WorkManager task that [BootReceiver] uses to get the day
 * re-armed after a restart or an in-place update.
 *
 * The work is enqueued against the workmanager plugin's own worker rather than
 * a bespoke one, because that worker is what boots the headless Flutter engine
 * and hands the task to the Dart callback dispatcher — the re-arm needs the Dart
 * side, which owns the location cache, the calculation method and the user's
 * settings. A plain `Worker` here would run, and compute nothing.
 *
 * Handing the work to WorkManager rather than starting a foreground service
 * also matters on Android 15+, where a `BOOT_COMPLETED` receiver may not launch
 * several foreground-service types at all.
 */
object BootRescheduleWork {

    /**
     * Must match `BackgroundScheduler.bootRescheduleTask` on the Dart side: the
     * background isolate dispatches on the task name it is handed.
     */
    const val TASK_NAME = "com.mawaqit.bootReschedule"

    /**
     * Enqueues the re-arm, replacing any earlier one that has not run yet.
     *
     * `REPLACE` rather than `KEEP` on purpose: a phone that reboots several
     * times, or is updated more than once, would otherwise queue one task per
     * event and boot the Flutter engine that many times for the same work. The
     * newest event is the one that matters — its alarms are the missing ones.
     */
    fun enqueue(context: Context) {
        val request = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
            .addTag(TASK_NAME)
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            TASK_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }
}
