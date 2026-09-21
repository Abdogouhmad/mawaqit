package com.mawaqit.mawaqit

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
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
 * NOTE: changing [sizeMode] (or the provider XML) changes the widget's size
 * metadata, which some launchers only re-read when the widget is removed and
 * re-added from the home screen. A blank view after an update is expected
 * until the widget is re-added.
 */
class PrayerWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Responsive(
        setOf(
            DpSize(110.dp, 90.dp), // narrow (3-cell-ish on dense grids)
            DpSize(180.dp, 90.dp), // default 2x1
            DpSize(260.dp, 90.dp), // wide 4x1
        ),
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        val name = prefs.getString("next_prayer_name", "—") ?: "—"
        val time = prefs.getString("next_prayer_time", "") ?: ""
        val minutesLeft = prefs.getInt("minutes_remaining", -1)
        // A Dart double is stored as raw long bits by home_widget — decode it.
        val progress = java.lang.Double
            .longBitsToDouble(prefs.getLong("progress", 0L))
            .toFloat()
            .coerceIn(0f, 1f)
        val sage = ColorProvider(Color(0xFF2E7D5B))
        val white = ColorProvider(Color.White)

        provideContent {
            val size = LocalSize.current
            PrayerWidgetContent(
                prayerName = name,
                prayerTime = time,
                minutesLeft = minutesLeft,
                progress = progress,
                compact = size.width < 150.dp, // hide subtitle at narrow widths
                sage = sage,
                white = white,
            )
        }
    }
}

@Composable
fun PrayerWidgetContent(
    prayerName: String,
    prayerTime: String,
    minutesLeft: Int,
    progress: Float,
    compact: Boolean,
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
                    fontSize = if (compact) 16.sp else 20.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            if (!compact) {
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
            }
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