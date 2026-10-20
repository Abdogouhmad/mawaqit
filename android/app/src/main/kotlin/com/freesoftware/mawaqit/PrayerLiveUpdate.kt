package com.freesoftware.mawaqit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject
import kotlin.math.ceil

/**
 * Builds, posts and retires the single pre-prayer **live update**.
 *
 * One promoted ongoing notification (stable id, so a new prayer replaces the
 * previous countdown instead of stacking) carries the whole pre-prayer alert:
 *
 * - **Before the prayer** it shows the prayer name with a system chronometer in
 *   countdown mode, a status-chip label ("Maghrib · 9m"), and a
 *   [Notification.ProgressStyle] bar that fills from the lead start to the
 *   prayer time. A one-minute alarm re-posts it so the chip label stays fresh.
 * - **At the prayer time** it flips to "It's time for …" with **Prayed** and
 *   **Dismiss** actions and removes itself after [IT_IS_TIME_TIMEOUT_MS], so a
 *   forgotten card cannot linger all day.
 *
 * Android promotes the notification on API 36+ (status-bar chip, top of the
 * shade and lockscreen); on older releases the same content renders as a
 * standard ongoing notification with a progress bar. Every API newer than the
 * release's minimum is guarded by an explicit `SDK_INT` check.
 */
object PrayerLiveUpdate {

    private const val TAG = "PrayerLiveUpdate"

    /** One live update at a time, whatever the occurrence — so a stable id. */
    private const val NOTIFICATION_ID = 2_900_000

    /**
     * The promotion request, written straight into the notification extras.
     * `androidx.core`'s `NotificationCompat.Builder.setRequestPromotedOngoing`
     * writes exactly this key/value; the constant itself only exists on API 37.
     */
    private const val EXTRA_REQUEST_PROMOTED = "android.requestPromotedOngoing"

    /** How long the "prayer time" card lingers before removing itself. */
    private const val IT_IS_TIME_TIMEOUT_MS = 30 * 60 * 1000L

    /** The app's emerald accent (`colors.xml`), used to tint the small icon. */
    private const val ACCENT_COLOR = 0xFF096444.toInt()

    /**
     * (Re)creates the dedicated channel. Silent by design: the audible pre-prayer
     * chime, when the user picked one, is played by the app itself, so a channel
     * sound would echo on top of it. `IMPORTANCE_LOW` (not `MIN`) keeps the card
     * promotable while staying out of the way.
     */
    fun ensureChannel(context: Context, payload: JSONObject?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val strings = liveStrings(
            context,
            payload?.optJSONObject(PrayerScheduler.KEY_STRINGS),
            payload?.optString(PrayerScheduler.KEY_NAME, "Prayer") ?: "Prayer",
        )
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(
                PrayerScheduler.CHANNEL_LIVE,
                strings.channelName,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = strings.channelDescription
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            },
        )
    }

    /** Posts (or replaces) the live update for a scheduled occurrence. */
    fun show(context: Context, id: Int, payloadFallback: String? = null) {
        val prefs = context.getSharedPreferences(PrayerScheduler.PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString("reminder_$id", null) ?: payloadFallback ?: return
        val payload = try {
            JSONObject(raw)
        } catch (_: Exception) {
            return
        }
        show(context, id, payload)
    }

    /**
     * Posts the live update for [reminder] immediately, storing it first so its
     * one-minute ticks survive the process. Used by the in-app path so the card
     * is up the moment the app crosses the lead boundary.
     */
    fun showNow(context: Context, reminder: Map<String, Any>) {
        val id = (reminder["id"] as? Number)?.toInt() ?: return
        val payload = JSONObject(reminder)
        val prayerId = payload.optString(PrayerScheduler.KEY_PRAYER_ID)
        if (prayerId.isNotEmpty() && prayerId == resolvedPrayerId(context)) {
            context.getSharedPreferences(PrayerScheduler.LIVE_PREFS, Context.MODE_PRIVATE)
                .edit().remove(PrayerScheduler.KEY_RESOLVED).commit()
        }
        context.getSharedPreferences(PrayerScheduler.PREFS, Context.MODE_PRIVATE)
            .edit().putString("reminder_$id", payload.toString()).commit()
        show(context, id, payload)
    }

    private fun show(context: Context, id: Int, payload: JSONObject) {
        val prayerMs = payload.optLong(PrayerScheduler.KEY_PRAYER_MS, 0L)
        if (prayerMs == 0L) return
        val prayerId = payload.optString(PrayerScheduler.KEY_PRAYER_ID)

        // Dismissed, marked prayed or opened already: retire the tick and stay
        // quiet. This is what stops a reschedule from resurrecting the card.
        if (prayerId.isNotEmpty() && prayerId == resolvedPrayerId(context)) {
            PrayerScheduler.cancelAlarm(context, id)
            cancel(context)
            return
        }

        if (!AlarmAccess.hasNotifications(context)) {
            Log.w(
                TAG,
                "Notifications are disabled for ${context.packageName} — " +
                    "the pre-prayer live update cannot be posted.",
            )
            return
        }

        ensureChannel(context, payload)
        val now = System.currentTimeMillis()
        val notification = if (now >= prayerMs) {
            // The prayer arrived: stop ticking and hand over to the actionable
            // card. It removes itself after the timeout.
            PrayerScheduler.cancelAlarm(context, id)
            buildItIsTimeNotification(context, id, payload, prayerMs)
        } else {
            val built = buildCountdownNotification(context, id, payload, prayerMs)
            // Re-arm a minute out, but never past the prayer time — the last
            // tick is the one that flips the card.
            PrayerScheduler.setAlarm(
                context,
                id,
                minOf(now + PrayerScheduler.TICK_MS, prayerMs),
                payload.toString(),
            )
            built
        }

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            Log.w(TAG, "Posting the pre-prayer live update was refused by the system.")
        }
    }

    /** Removes the live update without touching the resolved marker. */
    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /** Remembers that [prayerId] is done, so no reschedule re-posts it. */
    fun markResolved(context: Context, prayerId: String) {
        if (prayerId.isEmpty()) return
        context.getSharedPreferences(PrayerScheduler.LIVE_PREFS, Context.MODE_PRIVATE)
            .edit().putString(PrayerScheduler.KEY_RESOLVED, prayerId).commit()
    }

    /** The occurrence already dealt with, or null. */
    private fun resolvedPrayerId(context: Context): String? =
        context.getSharedPreferences(PrayerScheduler.LIVE_PREFS, Context.MODE_PRIVATE)
            .getString(PrayerScheduler.KEY_RESOLVED, null)

    /**
     * The card was tapped: the user is looking at the app, so retire the card.
     * The next tick, if one was already armed, finds the marker and stops.
     */
    fun onOpened(context: Context, prayerId: String) {
        markResolved(context, prayerId)
        cancel(context)
    }

    // ── Notification building ─────────────────────────────────────────────────

    private fun buildCountdownNotification(
        context: Context,
        id: Int,
        payload: JSONObject,
        prayerMs: Long,
    ): Notification {
        val name = payload.optString(PrayerScheduler.KEY_NAME, "Prayer")
        val strings = liveStrings(
            context,
            payload.optJSONObject(PrayerScheduler.KEY_STRINGS),
            name,
        )
        val remainingMin = ceil((prayerMs - System.currentTimeMillis()) / 60_000.0)
            .toInt().coerceAtLeast(0)
        val body = strings.body.replace("{time}", PrayerScheduler.timeLabel(context, prayerMs))
        val chip = strings.chip
            .replace("{prayer}", name)
            .replace("{minutes}", remainingMin.toString())
        val percent = progressPercent(prayerMs, payload.optInt(PrayerScheduler.KEY_LEAD_MIN, 10))
        val contentIntent = PrayerScheduler.openPendingIntent(
            context,
            payload.optString(PrayerScheduler.KEY_PRAYER_ID),
        )

        if (Build.VERSION.SDK_INT >= 36) {
            return Notification.Builder(context, PrayerScheduler.CHANNEL_LIVE)
                .setSmallIcon(R.drawable.ic_stat_mawaqit)
                .setColor(ACCENT_COLOR)
                .setContentTitle(name)
                .setContentText(body)
                .setShortCriticalText(chip)
                .setWhen(prayerMs)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setStyle(
                    Notification.ProgressStyle()
                        .setProgressSegments(
                            listOf(
                                Notification.ProgressStyle.Segment(100).setColor(ACCENT_COLOR)
                            )
                        )
                        .setProgress(percent)
                )
                .setContentIntent(contentIntent)
                .setCategory(Notification.CATEGORY_REMINDER)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                // `Notification.Builder.setRequestPromotedOngoing` and the
                // `Notification.EXTRA_REQUEST_PROMOTED_ONGOING` constant it writes
                // both land in API 37 — one release after promotion becomes
                // available — so the request is written as raw extras instead.
                .addExtras(promotionExtras())
                .build()
        }

        return NotificationCompat.Builder(context, PrayerScheduler.CHANNEL_LIVE)
            .setSmallIcon(R.drawable.ic_stat_mawaqit)
            .setColor(ACCENT_COLOR)
            .setContentTitle(name)
            .setContentText(body)
            .setWhen(prayerMs)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setProgress(100, percent, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(contentIntent)
            .build()
    }

    private fun buildItIsTimeNotification(
        context: Context,
        id: Int,
        payload: JSONObject,
        prayerMs: Long,
    ): Notification {
        val name = payload.optString(PrayerScheduler.KEY_NAME, "Prayer")
        val strings = liveStrings(
            context,
            payload.optJSONObject(PrayerScheduler.KEY_STRINGS),
            name,
        )
        val title = strings.itIsTime
        val body = strings.body.replace("{time}", PrayerScheduler.timeLabel(context, prayerMs))
        val contentIntent = PrayerScheduler.openPendingIntent(
            context,
            payload.optString(PrayerScheduler.KEY_PRAYER_ID),
        )
        val prayed = PrayerScheduler.prayedPendingIntent(context, id)
        val dismiss = PrayerScheduler.dismissPendingIntent(context, id)

        if (Build.VERSION.SDK_INT >= 36) {
            return Notification.Builder(context, PrayerScheduler.CHANNEL_LIVE)
                .setSmallIcon(R.drawable.ic_stat_mawaqit)
                .setColor(ACCENT_COLOR)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setContentIntent(contentIntent)
                .setShowWhen(false)
                .setTimeoutAfter(IT_IS_TIME_TIMEOUT_MS)
                .setCategory(Notification.CATEGORY_REMINDER)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .addAction(
                    Notification.Action.Builder(
                        Icon.createWithResource(context, R.drawable.ic_check),
                        strings.actionPrayed,
                        prayed,
                    ).build()
                )
                .addAction(
                    Notification.Action.Builder(
                        Icon.createWithResource(context, R.drawable.ic_close),
                        strings.actionDismiss,
                        dismiss,
                    ).build()
                )
                .build()
        }

        return NotificationCompat.Builder(context, PrayerScheduler.CHANNEL_LIVE)
            .setSmallIcon(R.drawable.ic_stat_mawaqit)
            .setColor(ACCENT_COLOR)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setShowWhen(false)
            .setTimeoutAfter(IT_IS_TIME_TIMEOUT_MS)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(R.drawable.ic_check, strings.actionPrayed, prayed)
            .addAction(R.drawable.ic_close, strings.actionDismiss, dismiss)
            .build()
    }

    /**
     * Fraction of the lead window already elapsed, as a 0–100 percentage.
     * `ProgressStyle` has no segments, so its max is 100 and the percentage is
     * the progress value directly.
     */
    private fun progressPercent(prayerMs: Long, leadMin: Int): Int {
        val total = leadMin.coerceAtLeast(1) * 60_000L
        val elapsed = System.currentTimeMillis() - (prayerMs - total)
        return ((elapsed * 100) / total).toInt().coerceIn(0, 100)
    }

    /**
     * The localized copy, passed down from Dart with the dynamic parts left as
     * `{prayer}` / `{time}` / `{minutes}` sentinels so the one-minute tick can
     * refresh them without another round-trip. Falls back to the English
     * `strings.xml` copy when a payload predates them or carries none — that
     * copy uses the same `{…}` sentinels, because a resource with two or more
     * format arguments has its positional markers stripped by aapt2 when
     * `formatted="false"`.
     */
    private data class LiveStrings(
        val channelName: String,
        val channelDescription: String,
        val body: String,
        val chip: String,
        val itIsTime: String,
        val actionPrayed: String,
        val actionDismiss: String,
    )

    private fun liveStrings(context: Context, json: JSONObject?, name: String): LiveStrings {
        fun value(key: String, fallback: String) =
            json?.optString(key)?.takeIf { it.isNotBlank() } ?: fallback
        return LiveStrings(
            channelName = value("channelName", context.getString(R.string.notif_live_channel)),
            channelDescription = value(
                "channelDescription",
                context.getString(R.string.notif_live_channel_description),
            ),
            body = value("body", context.getString(R.string.notif_live_body)),
            chip = value("chip", context.getString(R.string.notif_live_chip)),
            itIsTime = value("itIsTime", context.getString(R.string.notif_live_it_is_time))
                .replace("{prayer}", name),
            actionPrayed = value(
                "actionPrayed",
                context.getString(R.string.notif_live_action_prayed),
            ),
            actionDismiss = value(
                "actionDismiss",
                context.getString(R.string.notif_live_action_dismiss),
            ),
        )
    }

    /**
     * The promotion request, written directly as the key/value that
     * `NotificationCompat.Builder.setRequestPromotedOngoing` writes; the
     * framework constant itself only exists on API 37.
     */
    private fun promotionExtras(): Bundle = Bundle().apply {
        putBoolean(EXTRA_REQUEST_PROMOTED, true)
    }
}
