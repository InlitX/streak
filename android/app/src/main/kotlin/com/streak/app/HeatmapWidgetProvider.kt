package com.streak.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

class HeatmapWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_HOME_WIDGET_UPDATE) HeatmapRenderer.updateAll(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) HeatmapRenderer.update(context, appWidgetManager, id)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        HeatmapRenderer.update(context, appWidgetManager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            HeatmapConfig.clear(context, id)
            WidgetConfig.forget(context, id)
        }
    }

    private companion object {
        const val ACTION_HOME_WIDGET_UPDATE =
            "es.antonborri.home_widget.action.UPDATE_WIDGET"
    }
}
