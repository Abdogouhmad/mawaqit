// GENERATED CODE - DO NOT MODIFY BY HAND
package com.mawaqit.mawaqit

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class PrayerWidgetHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<PrayerWidgetHomeWidget>() {
  override val glanceAppWidget = PrayerWidgetHomeWidget()

  override fun previewFingerprint(context: Context): String =
      glanceAppWidget.previewFingerprint(context)
}
