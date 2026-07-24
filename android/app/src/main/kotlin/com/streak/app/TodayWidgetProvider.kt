package com.streak.app

import android.content.Context
import HomeWidgetGlanceWidgetReceiver

class TodayWidgetProvider : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) WidgetConfig.forget(context, id)
    }
}
