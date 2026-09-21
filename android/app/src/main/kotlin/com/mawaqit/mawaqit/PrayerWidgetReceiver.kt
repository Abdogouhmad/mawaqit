package com.mawaqit.mawaqit

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class PrayerWidgetReceiver : HomeWidgetGlanceWidgetReceiver<PrayerWidget>() {
    override val glanceAppWidget: PrayerWidget = PrayerWidget()
}