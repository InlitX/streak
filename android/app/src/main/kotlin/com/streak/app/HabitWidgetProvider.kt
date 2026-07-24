package com.streak.app

import android.content.Context
import HomeWidgetGlanceWidgetReceiver

class HabitWidgetProvider : HomeWidgetGlanceWidgetReceiver<HabitWidget>() {
    override val glanceAppWidget = HabitWidget()

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) WidgetConfig.forget(context, id)
    }
}
