package com.mawaqit.mawaqit

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat

/**
 * The system-level accesses the adhan depends on, in one place.
 *
 * Android grants these in stages and behind separate screens, and every OEM
 * (and every release) drops a different one: `POST_NOTIFICATIONS` (13+), exact
 * alarms (12+), full-screen intents (14+), Do Not Disturb access (6+), the
 * battery-optimisation exemption and "display over other apps". Miss any of
 * them and the adhan or the pre-prayer card is silently deferred or dropped —
 * the phone stays in Doze, the alarm never becomes exact, the call is swallowed
 * by silent mode, or the adhan stays a tray card because the screen was already
 * unlocked — so the app asks for them explicitly and keeps the schedule honest.
 *
 * [status] is a *read*: it never shows UI, so it is safe from a receiver or the
 * WorkManager isolate. [request] opens the matching system screen and returns
 * whether a screen could be opened at all.
 */
object AlarmAccess {

    const val KEY_NOTIFICATIONS = "notifications"
    const val KEY_EXACT_ALARMS = "exactAlarms"
    const val KEY_FULL_SCREEN_INTENT = "fullScreenIntent"

    /** Do Not Disturb access — lets [forceAdhanThroughDnd] lift silent mode. */
    const val KEY_POLICY_ACCESS = "policyAccess"

    /** Battery-optimisation exemption — keeps exact alarms out of Doze delays. */
    const val KEY_BATTERY = "batteryUnrestricted"

    /**
     * "Display over other apps" — the exemption from the background-activity
     * launch restriction that lets [AdhanScheduler.forceShowAdhan] put the
     * adhan on an *unlocked* screen.
     */
    const val KEY_OVERLAY = "overlay"

    private const val PREFS = "mawaqit_alarm_access"
    private const val KEY_DND_PREV_FILTER = "dnd_prev_filter"
    private const val KEY_DND_SINCE = "dnd_since_ms"

    /**
     * A DND filter left in place by a process that died mid-adhan is restored
     * once a *new* occurrence starts this long after the old one began. Well
     * past the longest adhan clip, so it can never cut a live alarm short.
     */
    private const val DND_STALE_MS = 10 * 60 * 1000L

    // ── Reads ─────────────────────────────────────────────────────────────────

    /** Whether the user allows the app to post notifications at all. */
    fun hasNotifications(context: Context): Boolean =
        NotificationManagerCompat.from(context).areNotificationsEnabled()

    /**
     * Whether `AlarmManager` may schedule exact alarms right now. `true` on
     * every release without the special access (pre-12 exact alarms are normal).
     */
    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager
        return am?.canScheduleExactAlarms() ?: true
    }

    /** Whether an alarm may take over the lockscreen (14+ makes this revocable). */
    fun canUseFullScreenIntent(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val nm = context.getSystemService(NotificationManager::class.java) ?: return true
        return nm.canUseFullScreenIntent()
    }

    /** "Do Not Disturb access" — required to change the interruption filter. */
    fun hasPolicyAccess(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val nm = context.getSystemService(NotificationManager::class.java) ?: return false
        return nm.isNotificationPolicyAccessGranted
    }

    /** Whether the app is exempt from battery optimisation (never Doze'd). */
    fun isBatteryUnrestricted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    /**
     * Whether the app may draw over other apps, i.e. whether
     * [AdhanScheduler.forceShowAdhan] can put the adhan presenter on screen
     * while the user is in another app.
     *
     * `true` on every release without the special access, so the alarm behaves
     * as it always did there and the Settings row is never shown as broken.
     */
    fun canDrawOverlays(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return Settings.canDrawOverlays(context)
    }

    /** Every access above, as the plain map the Flutter side parses. */
    fun status(context: Context): Map<String, Boolean> = mapOf(
        KEY_NOTIFICATIONS to hasNotifications(context),
        KEY_EXACT_ALARMS to canScheduleExactAlarms(context),
        KEY_FULL_SCREEN_INTENT to canUseFullScreenIntent(context),
        KEY_POLICY_ACCESS to hasPolicyAccess(context),
        KEY_BATTERY to isBatteryUnrestricted(context),
        KEY_OVERLAY to canDrawOverlays(context),
    )

    // ── Requests ──────────────────────────────────────────────────────────────

    /**
     * Opens the system screen that grants [key]. Returns false when there is
     * nothing to ask for on this release, or when no activity can handle the
     * intent — the Flutter side treats that as "already fine" and re-reads
     * [status] instead of nagging.
     */
    fun request(activity: Activity, key: String): Boolean {
        val intent: Intent = when (key) {
            KEY_NOTIFICATIONS -> notificationSettingsIntent(activity)
            KEY_EXACT_ALARMS -> exactAlarmIntent(activity) ?: return false
            KEY_FULL_SCREEN_INTENT -> fullScreenIntentIntent(activity) ?: return false
            KEY_POLICY_ACCESS -> policyAccessIntent(activity) ?: return false
            KEY_BATTERY -> batteryIntent(activity) ?: return false
            KEY_OVERLAY -> overlayIntent(activity) ?: return false
            else -> return false
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun notificationSettingsIntent(context: Context): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        } else {
            appDetailsIntent(context)
        }

    /** "Alarms & reminders" special access (12+); null below, where it's normal. */
    private fun exactAlarmIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        return Intent(
            Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
            Uri.parse("package:${context.packageName}"),
        )
    }

    /** Per-app "Full screen notifications" toggle (14+); null below. */
    private fun fullScreenIntentIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        return Intent(
            Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
            Uri.parse("package:${context.packageName}"),
        )
    }

    private fun policyAccessIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        // The extras highlight Mawaqit's row in the DND access list.
        val args = android.os.Bundle().apply {
            putString(":settings:fragment_args_key", context.packageName)
        }
        return Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .putExtra(":settings:fragment_args_key", context.packageName)
            .putExtra(":settings:show_fragment_args", args)
    }

    private fun batteryIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        return Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}"),
        )
    }

    /**
     * Per-app "Display over other apps" toggle — the switch that lets the adhan
     * take the screen while the phone is unlocked and in use. There is no
     * runtime dialog for it: the user has to confirm on this settings page.
     */
    private fun overlayIntent(context: Context): Intent? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        return Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}"),
        )
    }

    private fun appDetailsIntent(context: Context) =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}"))

    // ── Forcing the adhan through silent / Do Not Disturb ─────────────────────

    /**
     * Lifts Do Not Disturb to "alarms only" for the duration of the adhan, so
     * the call is still audible on a phone that is silenced or in a DND mode.
     * The previous filter is persisted *before* the change and restored by
     * [restoreDndFilter] on every teardown, so the phone is never left in a
     * mode the user did not choose.
     *
     * A no-op without "Do Not Disturb access" — and one where the adhan is
     * already the only thing allowed to make noise, since alarm usage rings
     * through every mode that permits alarms.
     */
    fun forceAdhanThroughDnd(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (!hasPolicyAccess(context)) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        if (nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALARMS) return

        // A previous alarm whose process died would otherwise strand the phone
        // in "alarms only" — clear it before taking over ourselves.
        restoreDndFilterIfStale(context)

        try {
            prefs(context).edit()
                .putInt(KEY_DND_PREV_FILTER, nm.currentInterruptionFilter)
                .putLong(KEY_DND_SINCE, System.currentTimeMillis())
                .commit()
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
        } catch (_: SecurityException) {
            // Access revoked between the check and the call — nothing to force.
        }
    }

    /**
     * Puts the interruption filter back the way the user had it. Safe to call
     * when no bypass is active, and idempotent, so every teardown path can call
     * it without tracking who started the bypass.
     */
    fun restoreDndFilter(context: Context) {
        val previous = prefs(context).getInt(KEY_DND_PREV_FILTER, -1)
        if (previous == -1) return
        prefs(context).edit()
            .remove(KEY_DND_PREV_FILTER)
            .remove(KEY_DND_SINCE)
            .commit()
        applyDndFilter(context, previous)
    }

    /** Restores a filter stranded by a process that died mid-adhan. */
    fun restoreDndFilterIfStale(context: Context) {
        val since = prefs(context).getLong(KEY_DND_SINCE, 0L)
        if (since == 0L) return
        if (System.currentTimeMillis() - since < DND_STALE_MS) return
        restoreDndFilter(context)
    }

    private fun applyDndFilter(context: Context, filter: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (!hasPolicyAccess(context)) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        try {
            nm.setInterruptionFilter(filter)
        } catch (_: SecurityException) {
            // Access revoked while the call rang — the user is in control.
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
