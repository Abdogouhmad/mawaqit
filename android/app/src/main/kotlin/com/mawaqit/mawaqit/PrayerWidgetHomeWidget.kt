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
import androidx.glance.layout.width
import androidx.compose.ui.unit.dp
import androidx.glance.layout.height
import androidx.glance.color.ColorProvider
import androidx.glance.text.TextStyle
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.GlanceTheme
import androidx.glance.layout.padding
import androidx.glance.appwidget.cornerRadius
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
      "5069e16e",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = PrayerWidgetData.fromPreferences(prefs)
    GlanceTheme {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.widgetBackground).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>()), contentAlignment = Alignment.Center) {
                Box(
                    modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFE2E6E1), night = Color(0xFF1E2A23))).cornerRadius(24.0.dp).padding(1.0.dp)
                ) {
                    Box(
                        modifier = GlanceModifier.background(ColorProvider(day = Color(0xFFF7F8F5), night = Color(0xFF131A16))).cornerRadius(23.0.dp)
                    ) {
                        Column(modifier = GlanceModifier.padding(start = 16.0.dp, top = 16.0.dp, end = 16.0.dp, bottom = 16.0.dp).fillMaxHeight(), horizontalAlignment = Alignment.Start) {
                            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF3E9B76))).width(8.0.dp).height(8.0.dp))
                                    Spacer(modifier = GlanceModifier.width(6.0.dp))
                                    Text(text = "MAWAQIT", style = TextStyle(color = ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFFA4F3CA)), fontSize = 12.sp, fontWeight = FontWeight.Bold))
                                }
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                Text(text = widgetData.locationShort ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.Normal))
                            }
                            Spacer(modifier = GlanceModifier.defaultWeight())
                            Column(horizontalAlignment = Alignment.Start) {
                                Text(text = "NEXT PRAYER", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp, fontWeight = FontWeight.Bold))
                                Spacer(modifier = GlanceModifier.height(4.0.dp))
                                Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                                Spacer(modifier = GlanceModifier.height(8.0.dp))
                                Text(text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80)), fontSize = 22.sp, fontWeight = FontWeight.Bold))
                                Spacer(modifier = GlanceModifier.height(4.0.dp))
                                Text(text = widgetData.nextPrayerTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 16.sp, fontWeight = FontWeight.Normal))
                            }
                            Spacer(modifier = GlanceModifier.defaultWeight())
                            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                if (widgetData.fajrIsActive == true) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80))).width(8.0.dp).height(8.0.dp))
                                } else {
                                    if (widgetData.fajrIsPast == true) {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))).width(6.0.dp).height(6.0.dp))
                                    } else {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))).width(6.0.dp).height(6.0.dp))
                                    }
                                }
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                if (widgetData.dhuhrIsActive == true) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80))).width(8.0.dp).height(8.0.dp))
                                } else {
                                    if (widgetData.dhuhrIsPast == true) {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))).width(6.0.dp).height(6.0.dp))
                                    } else {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))).width(6.0.dp).height(6.0.dp))
                                    }
                                }
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                if (widgetData.asrIsActive == true) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80))).width(8.0.dp).height(8.0.dp))
                                } else {
                                    if (widgetData.asrIsPast == true) {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))).width(6.0.dp).height(6.0.dp))
                                    } else {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))).width(6.0.dp).height(6.0.dp))
                                    }
                                }
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                if (widgetData.maghribIsActive == true) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80))).width(8.0.dp).height(8.0.dp))
                                } else {
                                    if (widgetData.maghribIsPast == true) {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))).width(6.0.dp).height(6.0.dp))
                                    } else {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))).width(6.0.dp).height(6.0.dp))
                                    }
                                }
                                Spacer(modifier = GlanceModifier.defaultWeight())
                                if (widgetData.ishaIsActive == true) {
                                    Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0xFF2E7D5B), night = Color(0xFF4ADE80))).width(8.0.dp).height(8.0.dp))
                                } else {
                                    if (widgetData.ishaIsPast == true) {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))).width(6.0.dp).height(6.0.dp))
                                    } else {
                                        Spacer(modifier = GlanceModifier.background(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))).width(6.0.dp).height(6.0.dp))
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

  }
}

data class PrayerWidgetData(
    val locationShort: String? = null,
    val nextPrayerName: String? = null,
    val nextPrayerCountdown: String? = null,
    val nextPrayerTime: String? = null,
    val fajrIsActive: Boolean? = null,
    val fajrIsPast: Boolean? = null,
    val dhuhrIsActive: Boolean? = null,
    val dhuhrIsPast: Boolean? = null,
    val asrIsActive: Boolean? = null,
    val asrIsPast: Boolean? = null,
    val maghribIsActive: Boolean? = null,
    val maghribIsPast: Boolean? = null,
    val ishaIsActive: Boolean? = null,
    val ishaIsPast: Boolean? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.PrayerWidget"

        fun fromPreferences(prefs: android.content.SharedPreferences): PrayerWidgetData {
            return PrayerWidgetData(
                locationShort = prefs.getString("${PREFERENCES_PREFIX}.locationShort", "—"),
                nextPrayerName = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerName", "ASR"),
                nextPrayerCountdown = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerCountdown", "01h 24m"),
                nextPrayerTime = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerTime", "3:45 PM"),
                fajrIsActive = if (prefs.contains("${PREFERENCES_PREFIX}.fajrIsActive")) prefs.getBoolean("${PREFERENCES_PREFIX}.fajrIsActive", false) else false,
                fajrIsPast = if (prefs.contains("${PREFERENCES_PREFIX}.fajrIsPast")) prefs.getBoolean("${PREFERENCES_PREFIX}.fajrIsPast", false) else false,
                dhuhrIsActive = if (prefs.contains("${PREFERENCES_PREFIX}.dhuhrIsActive")) prefs.getBoolean("${PREFERENCES_PREFIX}.dhuhrIsActive", false) else false,
                dhuhrIsPast = if (prefs.contains("${PREFERENCES_PREFIX}.dhuhrIsPast")) prefs.getBoolean("${PREFERENCES_PREFIX}.dhuhrIsPast", false) else false,
                asrIsActive = if (prefs.contains("${PREFERENCES_PREFIX}.asrIsActive")) prefs.getBoolean("${PREFERENCES_PREFIX}.asrIsActive", false) else false,
                asrIsPast = if (prefs.contains("${PREFERENCES_PREFIX}.asrIsPast")) prefs.getBoolean("${PREFERENCES_PREFIX}.asrIsPast", false) else false,
                maghribIsActive = if (prefs.contains("${PREFERENCES_PREFIX}.maghribIsActive")) prefs.getBoolean("${PREFERENCES_PREFIX}.maghribIsActive", false) else false,
                maghribIsPast = if (prefs.contains("${PREFERENCES_PREFIX}.maghribIsPast")) prefs.getBoolean("${PREFERENCES_PREFIX}.maghribIsPast", false) else false,
                ishaIsActive = if (prefs.contains("${PREFERENCES_PREFIX}.ishaIsActive")) prefs.getBoolean("${PREFERENCES_PREFIX}.ishaIsActive", false) else false,
                ishaIsPast = if (prefs.contains("${PREFERENCES_PREFIX}.ishaIsPast")) prefs.getBoolean("${PREFERENCES_PREFIX}.ishaIsPast", false) else false,
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
