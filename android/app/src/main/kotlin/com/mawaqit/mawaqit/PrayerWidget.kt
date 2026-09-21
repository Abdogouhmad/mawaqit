package com.mawaqit.mawaqit

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

/** FEAT: compact "next prayer" home-screen card. */
class PrayerWidget : GlanceAppWidget() {

    /** Needed so [PrayerWidgetReceiver] can refresh data before re-rendering. */
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { PrayerWidgetContent(currentState()) }
    }

    @Composable
    private fun PrayerWidgetContent(currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val name = prefs.getString("next_prayer_name", "—") ?: "—"
        val time = prefs.getString("next_prayer_time", "") ?: ""
        val minutes = prefs.getInt("minutes_remaining", -1)
        // A Dart double is stored as raw long bits by home_widget.
        val progress = java.lang.Double
            .longBitsToDouble(prefs.getLong("progress", 0L))
            .toFloat()
            .coerceIn(0f, 1f)
        val sage = Color(0xFF2E7D5B)

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
                    letterSpacing = 2.sp,
                    color = Color.White.copy(alpha = 0.7f),
                    fontWeight = FontWeight.Medium,
                ),
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                name,
                style = TextStyle(
                    fontSize = 28.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Spacer(GlanceModifier.height(8.dp))
            Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                Text(
                    time,
                    style = TextStyle(
                        fontSize = 18.sp,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold,
                    ),
                )
                if (minutes >= 0) {
                    Spacer(GlanceModifier.width(8.dp))
                    Text(
                        "in ${minutes}m",
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = Color.White.copy(alpha = 0.75f),
                            fontWeight = FontWeight.Medium,
                        ),
                    )
                }
            }
            Spacer(GlanceModifier.weight(1f))
            Row(GlanceModifier.fillMaxWidth().height(6.dp)) {
                Box(
                    GlanceModifier
                        .weight(progress)
                        .fillMaxHeight()
                        .background(Color.White),
                )
                Box(
                    GlanceModifier
                        .weight(1f - progress)
                        .fillMaxHeight()
                        .background(Color.White.copy(alpha = 0.25f)),
                )
            }
        }
    }
}