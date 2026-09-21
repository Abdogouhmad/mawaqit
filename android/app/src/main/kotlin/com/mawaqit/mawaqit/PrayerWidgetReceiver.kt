package com.mawaqit.mawaqit

import androidx.glance.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * FEAT: receiver for the next-prayer home-screen widget.
 *
 * Plain Glance receiver (not home_widget's subclass) — home_widget's
 * `updateWidget` re-renders it via an ACTION_APPWIDGET_UPDATE broadcast to
 * this exact class name, so `PrayerWidget` just re-reads the prefs bridge.
 */
class PrayerWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PrayerWidget()
}