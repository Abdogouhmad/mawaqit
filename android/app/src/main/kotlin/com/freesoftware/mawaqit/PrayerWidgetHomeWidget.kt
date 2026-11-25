// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This is a placeholder Glance (Jetpack Compose) widget.
package com.freesoftware.mawaqit

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
import androidx.glance.LocalSize
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.layout.Column
import androidx.glance.layout.Alignment
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.text.TextStyle
import androidx.glance.color.ColorProvider
import androidx.glance.GlanceTheme
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.layout.padding
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.ColorFilter
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.size
import es.antonborri.home_widget.HomeWidgetFonts
import androidx.glance.appwidget.cornerRadius
import androidx.glance.text.TextAlign
import androidx.core.os.ConfigurationCompat
import java.util.Locale
import androidx.glance.appwidget.SizeMode
import androidx.glance.action.clickable
import android.net.Uri
import es.antonborri.home_widget.actionStartActivity

class PrayerWidgetHomeWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override val sizeMode = SizeMode.Responsive(
      setOf(
          DpSize(110.dp, 110.dp),
          DpSize(250.dp, 110.dp),
      )
  )
  override val previewSizeMode = sizeMode

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
      "1618c0dd",
      hwLocales.joinToString(","),
      hwPreviewData.toString(),
    ).joinToString("|")
  }

  @Composable
  private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
    val prefs = currentState.preferences
    val widgetData = PrayerWidgetData.fromPreferences(prefs)
    GlanceTheme {
            Box(modifier = GlanceModifier.background(GlanceTheme.colors.widgetBackground).fillMaxSize().clickable(onClick = actionStartActivity<MainActivity>(context, Uri.parse("mawaqit:///times?homeWidget"))), contentAlignment = Alignment.Center) {
                when (LocalSize.current) {
                    DpSize(250.dp, 110.dp) -> {
                        if (widgetData.amoled == true) {
                            Box(
                                modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFE2E6E1), night = Color(0xFF1E2A23))).cornerRadius(24.0.dp).padding(1.0.dp)
                            ) {
                                Box(
                                    modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFF000000), night = Color(0xFF000000))).cornerRadius(23.0.dp)
                                ) {
                                    Column(modifier = GlanceModifier.fillMaxSize().padding(start = 4.0.dp, top = 4.0.dp, end = 4.0.dp, bottom = 4.0.dp), horizontalAlignment = Alignment.Start) {
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Image(modifier = GlanceModifier.size(16.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xF0355, 16f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                Text(modifier = GlanceModifier.padding(start = 2.0.dp, top = 0.0.dp, end = 0.0.dp, bottom = 0.0.dp), text = widgetData.locationShort ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium))
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.showHijri == true) {
                                                Text(text = widgetData.hijriDate ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.End))
                                            } else {

                                            }
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Column(horizontalAlignment = Alignment.Start) {
                                                Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                                                Text(modifier = GlanceModifier.padding(top = 2.0.dp), text = widgetData.nextPrayerTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium))
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            Text(text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80)), fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End))
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Row(modifier = GlanceModifier.defaultWeight(), verticalAlignment = Alignment.CenterVertically) {
                                                if (widgetData.fajrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.fajrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.dhuhrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.dhuhrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.asrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.asrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.maghribIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.maghribIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.ishaIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.ishaIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                    }
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.showQuickActions == true) {
                                                Text(text = context.getString(R.string.home_widget_prayer_widget_t_f39c05de), style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.End))
                                            } else {

                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            Box(
                                modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFE2E6E1), night = Color(0xFF1E2A23))).cornerRadius(24.0.dp).padding(1.0.dp)
                            ) {
                                Box(
                                    modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFF7F8F5), night = Color(0xFF131A16))).cornerRadius(23.0.dp)
                                ) {
                                    Column(modifier = GlanceModifier.fillMaxSize().padding(start = 4.0.dp, top = 4.0.dp, end = 4.0.dp, bottom = 4.0.dp), horizontalAlignment = Alignment.Start) {
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Image(modifier = GlanceModifier.size(16.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xF0355, 16f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                Text(modifier = GlanceModifier.padding(start = 2.0.dp, top = 0.0.dp, end = 0.0.dp, bottom = 0.0.dp), text = widgetData.locationShort ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium))
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.showHijri == true) {
                                                Text(text = widgetData.hijriDate ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.End))
                                            } else {

                                            }
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Column(horizontalAlignment = Alignment.Start) {
                                                Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                                                Text(modifier = GlanceModifier.padding(top = 2.0.dp), text = widgetData.nextPrayerTime ?: "", style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium))
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            Text(text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80)), fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End))
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            Row(modifier = GlanceModifier.defaultWeight(), verticalAlignment = Alignment.CenterVertically) {
                                                if (widgetData.fajrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.fajrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.dhuhrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.dhuhrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.asrIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.asrIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.maghribIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.maghribIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                    }
                                                }
                                                Spacer(modifier = GlanceModifier.defaultWeight())
                                                if (widgetData.ishaIsActive == true) {
                                                    Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                                } else {
                                                    if (widgetData.ishaIsPast == true) {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                    } else {
                                                        Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                    }
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.showQuickActions == true) {
                                                Text(text = context.getString(R.string.home_widget_prayer_widget_t_f39c05de), style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.End))
                                            } else {

                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else -> {
                        if (widgetData.amoled == true) {
                            Box(
                                modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFE2E6E1), night = Color(0xFF1E2A23))).cornerRadius(24.0.dp).padding(1.0.dp)
                            ) {
                                Box(
                                    modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFF000000), night = Color(0xFF000000))).cornerRadius(23.0.dp)
                                ) {
                                    Column(modifier = GlanceModifier.fillMaxSize().padding(start = 4.0.dp, top = 4.0.dp, end = 4.0.dp, bottom = 4.0.dp), horizontalAlignment = Alignment.Start) {
                                        Column(horizontalAlignment = Alignment.Start) {
                                            Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                                            Text(modifier = GlanceModifier.padding(top = 2.0.dp), text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80)), fontSize = 22.sp, fontWeight = FontWeight.Bold))
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            if (widgetData.fajrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.fajrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.dhuhrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.dhuhrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.asrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.asrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.maghribIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.maghribIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.ishaIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.ishaIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x99B8C0BA), night = Color(0x99B8C0BA))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x445A655D), night = Color(0x445A655D))))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            Box(
                                modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFE2E6E1), night = Color(0xFF1E2A23))).cornerRadius(24.0.dp).padding(1.0.dp)
                            ) {
                                Box(
                                    modifier = GlanceModifier.fillMaxSize().background(ColorProvider(day = Color(0xFFF7F8F5), night = Color(0xFF131A16))).cornerRadius(23.0.dp)
                                ) {
                                    Column(modifier = GlanceModifier.fillMaxSize().padding(start = 4.0.dp, top = 4.0.dp, end = 4.0.dp, bottom = 4.0.dp), horizontalAlignment = Alignment.Start) {
                                        Column(horizontalAlignment = Alignment.Start) {
                                            Text(text = widgetData.nextPrayerName ?: "", style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                                            Text(modifier = GlanceModifier.padding(top = 2.0.dp), text = widgetData.nextPrayerCountdown ?: "", style = TextStyle(color = ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80)), fontSize = 22.sp, fontWeight = FontWeight.Bold))
                                        }
                                        Spacer(modifier = GlanceModifier.defaultWeight())
                                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                            if (widgetData.fajrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.fajrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.dhuhrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.dhuhrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.asrIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.asrIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.maghribIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.maghribIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
                                                }
                                            }
                                            Spacer(modifier = GlanceModifier.defaultWeight())
                                            if (widgetData.ishaIsActive == true) {
                                                Image(modifier = GlanceModifier.size(9.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 9f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0xFF0F5C4A), night = Color(0xFF4ADE80))))
                                            } else {
                                                if (widgetData.ishaIsPast == true) {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x666F7A72), night = Color(0x668A918C))))
                                                } else {
                                                    Image(modifier = GlanceModifier.size(6.dp), provider = ImageProvider(HomeWidgetFonts.iconBitmap(context, R.font.hw_font_prayer_widget__icons_materialicons, 0xE163, 6f)), contentDescription = null, colorFilter = ColorFilter.tint(ColorProvider(day = Color(0x336F7A72), night = Color(0x338A918C))))
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
    }

  }
}

data class PrayerWidgetData(
    val amoled: Boolean? = null,
    val nextPrayerName: String? = null,
    val nextPrayerCountdown: String? = null,
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
    val locationShort: String? = null,
    val showHijri: Boolean? = null,
    val hijriDate: String? = null,
    val nextPrayerTime: String? = null,
    val showQuickActions: Boolean? = null,
) {
    companion object {
        private const val PREFERENCES_PREFIX = "home_widget.PrayerWidget"

        fun fromPreferences(prefs: android.content.SharedPreferences): PrayerWidgetData {
            return PrayerWidgetData(
                amoled = if (prefs.contains("${PREFERENCES_PREFIX}.amoled")) prefs.getBoolean("${PREFERENCES_PREFIX}.amoled", false) else false,
                nextPrayerName = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerName", "—"),
                nextPrayerCountdown = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerCountdown", "—"),
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
                locationShort = prefs.getString("${PREFERENCES_PREFIX}.locationShort", "—"),
                showHijri = if (prefs.contains("${PREFERENCES_PREFIX}.showHijri")) prefs.getBoolean("${PREFERENCES_PREFIX}.showHijri", false) else true,
                hijriDate = prefs.getString("${PREFERENCES_PREFIX}.hijriDate", ""),
                nextPrayerTime = prefs.getString("${PREFERENCES_PREFIX}.nextPrayerTime", "—"),
                showQuickActions = if (prefs.contains("${PREFERENCES_PREFIX}.showQuickActions")) prefs.getBoolean("${PREFERENCES_PREFIX}.showQuickActions", false) else true,
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
