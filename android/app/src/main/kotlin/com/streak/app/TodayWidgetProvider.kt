package com.streak.app

import HomeWidgetGlanceWidgetReceiver

class TodayWidgetProvider : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()
}
