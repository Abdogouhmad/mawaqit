package com.mawaqit.mawaqit

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
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
 */
class PrayerWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
        val name = prefs.getString("next_prayer_name", "—") ?: "—"
        val time = prefs.getString("next_prayer_time", "") ?: ""
        val minutes = prefs.getInt("minutes_remaining", -1)
        // A Dart double is stored as raw long bits by home_widget — decode it.
        val progress = java.lang.Double
            .longBitsToDouble(prefs.getLong("progress", 0L))
            .toFloat()
            .coerceIn(0f, 1f)
        val sage = ColorProvider(Color(0xFF2E7D5B))
        val white = ColorProvider(Color.White)

        provideContent {
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(sage)
                    .padding(16.dp),
                verticalAlignment = Alignment.Vertical.Top,
                horizontalAlignment = Alignment.Horizontal.Start,
            ) {
                Text(
                    "NEXT PRAYER",
                    style = TextStyle(
                        fontSize = 11.sp,
                        color = ColorProvider(Color.White.copy(alpha = 0.7f)),
                        fontWeight = FontWeight.Medium,
                    ),
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    name,
                    style = TextStyle(
                        fontSize = 28.sp,
                        color = white,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                Spacer(GlanceModifier.height(8.dp))
                Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                    Text(
                        time,
                        style = TextStyle(
                            fontSize = 18.sp,
                            color = white,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                    if (minutes >= 0) {
                        Spacer(GlanceModifier.width(8.dp))
                        Text(
                            "in ${minutes}m",
                            style = TextStyle(
                                fontSize = 14.sp,
                                color = ColorProvider(Color.White.copy(alpha = 0.75f)),
                                fontWeight = FontWeight.Medium,
                            ),
                        )
                    }
                }
                Spacer(GlanceModifier.height(6.dp))
                LinearProgressIndicator(
                    progress = progress,
                    modifier = GlanceModifier.fillMaxWidth().height(6.dp),
                    color = white,
                    backgroundColor = ColorProvider(Color.White.copy(alpha = 0.25f)),
                )
            }
        }
    }
}