// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This is a placeholder Glance (Jetpack Compose) widget.
package com.mawaqit.mawaqit

import androidx.compose.runtime.Composable
import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.text.TextStyle
import androidx.glance.GlanceTheme
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.color.ColorProvider
import androidx.compose.ui.unit.dp
import androidx.glance.layout.padding
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity

class PrayerWidgetHomeWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent { WidgetContent(context, currentState()) }
  }

  override suspend fun providePreview(context: Context, widgetCategory: Int) {
    provideContent { WidgetContent(context, HomeWidgetGlanceState(HomeWidgetPlugin.getData(context))) }
  }

  fun previewFingerprint(context: Context): String {
    val hwLocales = hwCurrentLocales(context)
    val hwPreviewData =
        PrayerWidgetData.fromPreferences(HomeWidgetPlugin.getData(context))
    return listOf(
      "8dcd09c8",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = PrayerWidgetData.fromPreferences(prefs)
    GlanceTheme {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.widgetBackground).padding(16.dp).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.Center) {
                Column(modifier = GlanceModifier.padding(start = 12.0.dp, top = 12.0.dp, end = 12.0.dp, bottom = 12.0.dp).fillMaxHeight(), horizontalAlignment = Alignment.Start) {
                    Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 22.sp, fontWeight = FontWeight.Bold))
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Text(text = widgetData.nextPrayerTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 22.sp, fontWeight = FontWeight.Normal))
                    }
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    Text(text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = widgetData.fajrName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            Text(text = widgetData.fajrTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                        }
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = widgetData.dhuhrName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            Text(text = widgetData.dhuhrTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                        }
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = widgetData.asrName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            Text(text = widgetData.asrTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                        }
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = widgetData.maghribName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            Text(text = widgetData.maghribTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                        }
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = widgetData.ishaName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            Text(text = widgetData.ishaTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                        }
                    }
                }
            }
    }

  }
}

data class PrayerWidgetData(
    val nextPrayerName: String? = null,
    val nextPrayerTime: String? = null,
    val nextPrayerCountdown: String? = null,
    val fajrName: String? = null,
    val fajrTime: String? = null,
    val dhuhrName: String? = null,
    val dhuhrTime: String? = null,
    val asrName: String? = null,
    val asrTime: String? = null,
    val maghribName: String? = null,
    val maghribTime: String? = null,
    val ishaName: String? = null,
    val ishaTime: String? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.PrayerWidget"

        fun fromPreferences(prefs: android.content.SharedPreferences): PrayerWidgetData {
            return PrayerWidgetData(
                nextPrayerName = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerName", "—"),
                nextPrayerTime = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerTime", "--:--"),
                nextPrayerCountdown = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerCountdown", ""),
                fajrName = prefs.getString("${PREFERENCES_PREFIX}.fajrName", null),
                fajrTime = prefs.getString("${PREFERENCES_PREFIX}.fajrTime", null),
                dhuhrName = prefs.getString("${PREFERENCES_PREFIX}.dhuhrName", null),
                dhuhrTime = prefs.getString("${PREFERENCES_PREFIX}.dhuhrTime", null),
                asrName = prefs.getString("${PREFERENCES_PREFIX}.asrName", null),
                asrTime = prefs.getString("${PREFERENCES_PREFIX}.asrTime", null),
                maghribName = prefs.getString("${PREFERENCES_PREFIX}.maghribName", null),
                maghribTime = prefs.getString("${PREFERENCES_PREFIX}.maghribTime", null),
                ishaName = prefs.getString("${PREFERENCES_PREFIX}.ishaName", null),
                ishaTime = prefs.getString("${PREFERENCES_PREFIX}.ishaTime", null),
            )
        }
    }
}


private fun hwCurrentLocales(context: Context): List<String> {
    val configured = ConfigurationCompat
        .getLocales(context.resources.configuration)
    val tags = mutableListOf<String>()
    for (index in 0 until configured.size()) {
        val locale = configured[index] ?: continue
        val tag = locale.toLanguageTag()
        if (tag.isNotEmpty() && tag != "und") tags.add(tag)
    }
    if (tags.isEmpty()) {
        val fallback = Locale.getDefault().toLanguageTag()
        if (fallback.isNotEmpty() && fallback != "und") tags.add(fallback)
    }
    return tags
}
