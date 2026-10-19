package com.freesoftware.mawaqit

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Owns the exact alarms and the payload storage behind the pre-prayer live
 * update.
 *
 * Each occurrence is stored as one JSON payload (see [KEY_*]) keyed by its
 * native id, and armed as one `AlarmManager` entry. The payload is deliberately
 * copied into the alarm's `PendingIntent` as well: `SharedPreferences` writes are
 * asynchronous, and a user swiping the app away right after a reschedule could
 * otherwise leave an alarm with no stored entry. The receiver then rebuilds the
 * live update from the intent copy instead of dropping the occurrence.
 *
 * The presentation itself lives in [PrayerLiveUpdate]; this object only owns the
 * alarms and the storage.
 */
object PrayerScheduler {

    const val ACTION_SHOW = "com.mawaqit.action.SHOW_REMINDER"
    const val ACTION_PRAYED = "com.mawaqit.action.PRAYED_REMINDER"
    const val ACTION_DISMISS = "com.mawaqit.action.DISMISS_REMINDER"

    /** Tapping the live update opens the app and takes the occurrence over. */
    const val ACTION_OPEN = "com.mawaqit.action.OPEN_REMINDER"

    const val EXTRA_ID = "com.mawaqit.extra.ID"
    const val EXTRA_PRAYER_ID = "com.mawaqit.extra.PRAYER_ID"

    /**
     * Full reminder payload embedded in the alarm [PendingIntent]. SharedPreferences
     * writes are asynchronous, so a user swiping the app away right after a
     * reschedule could leave the alarm with no stored entry — the receiver then
     * falls back to this copy instead of dropping the occurrence silently.
     */
    const val EXTRA_REMINDER = "com.mawaqit.extra.REMINDER_JSON"

    // Payload keys, shared with the Dart reminder maps handed to `schedule`.
    const val KEY_PRAYER_ID = "prayerId"
    const val KEY_NAME = "name"
    const val KEY_PRAYER_MS = "prayerTimestampMs"
    const val KEY_LEAD_MIN = "leadMinutes"
    const val KEY_STRINGS = "strings"

    /** Silent channel the live countdown is posted on. */
    const val CHANNEL_LIVE = "prayer_live_countdown_v1"

    /** One JSON payload per scheduled occurrence. */
    const val PREFS = "mawaqit_reminders"

    /**
     * "This occurrence is already dealt with" marker, kept apart from [PREFS]
     * because [cancelAll] clears the payloads on every reschedule: a reschedule
     * must never resurrect a countdown the user dismissed, marked prayed, or
     * opened.
     */
    const val LIVE_PREFS = "mawaqit_live_update"
    const val KEY_RESOLVED = "resolved"

    val TICK_MS = 60_000L

    // Distinct request-code buckets keep PendingIntents unique per purpose.
    private const val REQ_SHOW = 4000
    private const val REQ_PRAYED = 5000
    private const val REQ_DISMISS = 6000

    /** Stable across occurrences: only one live update exists at a time. */
    private const val REQ_OPEN = 7000

    /**
     * Formats an epoch in the device's own clock convention.
     *
     * Read live from the system rather than persisted when the reminder was
     * armed: these alarms are scheduled hours ahead, and a user who switches
     * their phone to 24-hour in between should not get a card that disagrees
     * with every other clock in the app. `Locale.getDefault()` (rather than a
     * pinned `Locale.US`) keeps the same convention for non-English locales.
     */
    fun timeLabel(context: Context, epochMs: Long): String =
        SimpleDateFormat(
            if (android.text.format.DateFormat.is24HourFormat(context)) "HH:mm" else "h:mm a",
            Locale.getDefault(),
        ).format(Date(epochMs))

    /** Schedules a live-update countdown for each upcoming prayer. */
    fun schedule(context: Context, reminders: List<Map<String, Any>>) {
        cancelAll(context)

        val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        val armed = ArrayList<Triple<Int, Long, String>>()
        for (reminder in reminders) {
            val id = (reminder["id"] as? Number)?.toInt() ?: continue
            val leadMs = (reminder["timestampMs"] as? Number)?.toLong() ?: continue
            val payload = JSONObject(reminder).toString()
            editor.putString("reminder_$id", payload)
            armed += Triple(id, leadMs, payload)
        }

        // commit(), not apply(): an alarm can fire seconds later with the
        // process already swiped away, and the async disk write of apply() may
        // not have landed yet — the receiver would then have no payload at all.
        editor.commit()

        // The channel is created once from the first payload's localized copy;
        // its label follows the active language because createNotificationChannel
        // updates an existing channel's name and description.
        armed.firstOrNull()?.let { (_, _, payload) ->
            PrayerLiveUpdate.ensureChannel(context, JSONObject(payload))
        }
        armed.forEach { (id, leadMs, payload) -> setAlarm(context, id, leadMs, payload) }
    }

    fun cancelAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val keys = prefs.all.keys.filter { it.startsWith("reminder_") }
        keys.forEach { key ->
            val id = key.removePrefix("reminder_").toIntOrNull() ?: return@forEach
            am.cancel(showPendingIntent(context, id))
        }
        prefs.edit().clear().apply()
        PrayerLiveUpdate.cancel(context)
    }

    fun setAlarm(context: Context, id: Int, atEpochMs: Long, payloadJson: String? = null) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = showPendingIntent(context, id, payloadJson)
        // A lead time already in the past (a reschedule inside the countdown
        // window, or a reboot mid-window) must post immediately, not be pushed
        // a minute into the future — hence the one-second floor rather than a
        // full tick. The receiver itself re-arms the next tick.
        val trigger = maxOf(atEpochMs, System.currentTimeMillis() + 1000L)
        // Without the "Alarms & reminders" special access Android 12+ refuses
        // exact alarms outright; `setAndAllowWhileIdle` still fires, only
        // batched into the next maintenance window — a reminder the user may
        // only see minutes late, which is why the app asks for the access
        // (see [AlarmAccess.KEY_EXACT_ALARMS]) and shows it in Settings.
        if (AlarmAccess.canScheduleExactAlarms(context)) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
        }
    }

    fun cancelAlarm(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(showPendingIntent(context, id))
    }

    /**
     * Cancels one scheduled reminder: its alarm, its stored payload and the live
     * update. Used when the in-app path takes an occurrence over, or when the
     * user removes it from Settings.
     */
    fun cancelOne(context: Context, id: Int) {
        cancelAlarm(context, id)
        removePref(context, id)
        PrayerLiveUpdate.cancel(context)
    }

    fun removePref(context: Context, id: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove("reminder_$id").apply()
    }

    fun showPendingIntent(context: Context, id: Int, payloadJson: String? = null) =
        PendingIntent.getBroadcast(
            context,
            REQ_SHOW + id,
            Intent(context, PrayerReminderReceiver::class.java)
                .setAction(ACTION_SHOW)
                .putExtra(EXTRA_ID, id)
                .apply { if (payloadJson != null) putExtra(EXTRA_REMINDER, payloadJson) },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** The occurrence id (`2026-09-21_maghrib`) backing a scheduled reminder. */
    fun prayerId(context: Context, id: Int): String? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("reminder_$id", null) ?: return null
        return try {
            JSONObject(raw).optString(KEY_PRAYER_ID).takeIf { it.isNotBlank() }
        } catch (_: Exception) {
            null
        }
    }

    fun actionPendingIntent(
        context: Context,
        id: Int,
        action: String,
        base: Int,
    ): PendingIntent = PendingIntent.getBroadcast(
        context,
        base + id,
        Intent(context, PrayerReminderReceiver::class.java)
            .setAction(action)
            .putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun prayedPendingIntent(context: Context, id: Int): PendingIntent =
        actionPendingIntent(context, id, ACTION_PRAYED, REQ_PRAYED)

    fun dismissPendingIntent(context: Context, id: Int): PendingIntent =
        actionPendingIntent(context, id, ACTION_DISMISS, REQ_DISMISS)

    /**
     * Opens the app when the live update is tapped. A plain activity intent
     * (rather than a broadcast) is deliberate: the system exempts a
     * notification tap from the background-activity-start restrictions, so the
     * app comes forward even though the reminder outlives the process. The
     * occurrence is carried along so [MainActivity] can retire the notification.
     */
    fun openPendingIntent(context: Context, prayerId: String): PendingIntent =
        PendingIntent.getActivity(
            context,
            REQ_OPEN,
            Intent(context, MainActivity::class.java)
                .setAction(PrayerScheduler.ACTION_OPEN)
                .putExtra(EXTRA_PRAYER_ID, prayerId)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP,
                ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
