package com.streak.app

import android.content.Context
import HomeWidgetGlanceWidgetReceiver

class StatsWidgetProvider : HomeWidgetGlanceWidgetReceiver<StatsWidget>() {
    override val glanceAppWidget = StatsWidget()

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) WidgetConfig.forget(context, id)
    }
}
