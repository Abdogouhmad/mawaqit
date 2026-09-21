package com.mawaqit.mawaqit

import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * FEAT: compact "next prayer" home-screen card.
 *
 * Reads the snapshot that [WidgetService] (Flutter) pushed through home_widget's
 * `HomeWidgetPreferences` bridge on every re-render. Decoupled from the
 * plugin's own Glance helper classes so it only depends on androidx.glance.
 *
 * Responsive: [sizeMode] registers distinct widths (180dp / 260dp) so the
 * launcher has valid resize steps for 2x1 and 4x1. Content avoids
 * `LocalSize.current` — reading a `CompositionLocal<DpSize>` (inline class)
 * trips a known Kotlin backend bug (`Couldn't inline method call`) — so the
 * single layout below is sized and `maxLines = 1`-clipped to fit every
 * registered width instead. Every Text is `maxLines = 1`: glance text that
 * overflows its bounds can render fully clipped/invisible rather than
 * truncated depending on host.
 *
 * Every data read is wrapped in [runCatching] so a malformed/missing row in
 * the home_widget preferences bridge can never throw inside the composition —
 * an uncaught throwable there is exactly what makes Glance revert to its
 * "Can't show content" error layout. [onCompositionError] logs the real
 * stack so a still-broken widget can be diagnosed from logcat.
 *
 * NOTE: changing [sizeMode] (or the provider XML) changes the widget's size
 * metadata, which some launchers only re-read when the widget is removed and
 * re-added from the home screen. A blank view after an update is expected
 * until the widget is re-added.
 */
class PrayerWidget : GlanceAppWidget() {

    // SizeMode.Single renders once at the widget-info size (180x90 / 2x1)
    // using the size declared in prayer_widget_info.xml. With Responsive,
    // Glance re-composes per requested size and reads a pinned LocalSize,
    // which trips a known Kotlin backend inline-class bug ("Couldn't inline
    // method call") that manifests as the blank "Can't show content" card.
    // Single size mode avoids that entirely — the layout clips (maxLines = 1)
    // so it still fits wide 4x1 hosts.
    override val sizeMode = SizeMode.Single

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        // Defensive reads: never let a bad row turn into Glance's error layout.
        val name = runCatching { prefs.getString("next_prayer_name", "Mawaqit") }
            .getOrNull()?.blankToNull() ?: "Next prayer"
        val time = runCatching { prefs.getString("next_prayer_time", "") }
            .getOrNull()?.blankToNull() ?: "—"
        val minutesLeft = runCatching { prefs.getInt("minutes_remaining", -1) }
            .getOrNull() ?: -1
        // A Dart double is stored as raw long bits by home_widget — decode it,
        // clamping non-finite/out-of-range values to a valid 0..1 progress.
        val progress = runCatching {
            java.lang.Double.longBitsToDouble(prefs.getLong("progress", 0L)).toFloat()
        }.getOrElse { 0f }
            .takeIf { it.isFinite() && !it.isNaN() }
            ?.coerceIn(0f, 1f) ?: 0f
        val sage = ColorProvider(Color(0xFF2E7D5B))
        val white = ColorProvider(Color.White)

        provideContent {
            PrayerWidgetContent(
                prayerName = name,
                prayerTime = time,
                minutesLeft = minutesLeft,
                progress = progress,
                sage = sage,
                white = white,
            )
        }
    }

    override fun onCompositionError(
        context: Context,
        glanceId: GlanceId,
        appWidgetId: Int,
        throwable: Throwable,
    ) {
        Log.e("PrayerWidget", "widget composition failed (appWidgetId=$appWidgetId)", throwable)
        super.onCompositionError(context, glanceId, appWidgetId, throwable)
    }
}

/** Treats blank strings from the prefs bridge as "unset". */
private fun String?.blankToNull(): String? =
    this?.takeIf { it.isNotBlank() }

@Composable
fun PrayerWidgetContent(
    prayerName: String,
    prayerTime: String,
    minutesLeft: Int,
    progress: Float,
    sage: ColorProvider,
    white: ColorProvider,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(sage)
            .cornerRadius(24.dp)
            .padding(12.dp),
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Text(
                text = prayerName,
                maxLines = 1,
                style = TextStyle(
                    color = white,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = if (minutesLeft >= 0)
                    "in $minutesLeft min • $prayerTime"
                else
                    prayerTime,
                maxLines = 1,
                style = TextStyle(
                    color = ColorProvider(Color.White.copy(alpha = 0.8f)),
                    fontSize = 13.sp,
                ),
            )
            Spacer(GlanceModifier.defaultWeight())
            LinearProgressIndicator(
                progress = progress,
                modifier = GlanceModifier.fillMaxWidth().height(6.dp),
                color = white,
                backgroundColor = ColorProvider(Color.White.copy(alpha = 0.25f)),
            )
        }
    }
}