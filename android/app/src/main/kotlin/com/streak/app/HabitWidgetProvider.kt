package com.streak.app

import HomeWidgetGlanceWidgetReceiver

class HabitWidgetProvider : HomeWidgetGlanceWidgetReceiver<HabitWidget>() {
    override val glanceAppWidget = HabitWidget()
}
