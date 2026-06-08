package com.streak.app

import HomeWidgetGlanceWidgetReceiver

class StatsWidgetProvider : HomeWidgetGlanceWidgetReceiver<StatsWidget>() {
    override val glanceAppWidget = StatsWidget()
}
