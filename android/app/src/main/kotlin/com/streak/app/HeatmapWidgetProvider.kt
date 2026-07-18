package com.streak.app

import android.content.Context
import HomeWidgetGlanceWidgetReceiver

class HeatmapWidgetProvider : HomeWidgetGlanceWidgetReceiver<HeatmapWidget>() {
    override val glanceAppWidget = HeatmapWidget()

    // Drop the per-widget habit choice so a reused appWidgetId can't inherit it.
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        for (id in appWidgetIds) HeatmapConfig.clear(context, id)
    }
}
