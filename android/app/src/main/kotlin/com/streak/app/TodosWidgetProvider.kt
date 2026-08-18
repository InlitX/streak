package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.Context
import HomeWidgetGlanceWidgetReceiver

class TodosWidgetProvider : HomeWidgetGlanceWidgetReceiver<TodosWidget>() {
    override val glanceAppWidget = TodosWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        WidgetRefreshReceiver.keepFresh(context)
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) WidgetConfig.forget(context, id)
    }
}
