package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.state.GlanceStateDefinition
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import androidx.glance.layout.*
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.text.FontWeight
import androidx.glance.appwidget.cornerRadius
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity
import androidx.glance.unit.ColorProvider
import org.json.JSONObject

class StatsWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        // Read inside composition: update() recomposes without re-running this.
        provideContent {
            currentState<HomeWidgetGlanceState>()
            Content(context, WidgetStyle.loadFor(context, appWidgetId))
        }
    }

    @Composable
    private fun Content(context: Context, style: WidgetStyle) {
        val data = loadData(context)
        val summary = data?.optJSONObject("summary")
        val done = summary?.optInt("doneToday") ?: 0
        val total = summary?.optInt("total") ?: 0
        val best = summary?.optInt("bestStreak") ?: 0
        val brand = androidx.compose.ui.graphics.Color(0xFF7C5CFC)

        WidgetSurface(style) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(16.dp)
                .clickable(actionStartActivity<MainActivity>()),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "$done/$total",
                style = TextStyle(
                    color = ColorProvider(brand),
                    fontSize = 34.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Text(
                text = "done today",
                style = TextStyle(
                    color = ColorProvider(style.muted),
                    fontSize = 13.sp
                )
            )
            Spacer(modifier = GlanceModifier.height(10.dp))
            Text(
                text = "🔥 $best best streak",
                style = TextStyle(
                    color = ColorProvider(style.content),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            )
        }
        }
    }

    private fun loadData(context: Context): JSONObject? {
        return try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val json = prefs.getString("habits_data", null)
            if (json != null) JSONObject(json) else null
        } catch (e: Exception) {
            null
        }
    }
}
