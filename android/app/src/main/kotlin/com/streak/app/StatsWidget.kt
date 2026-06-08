package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
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

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context) }
    }

    @Composable
    private fun Content(context: Context) {
        val data = loadData(context)
        val summary = data?.optJSONObject("summary")
        val done = summary?.optInt("doneToday") ?: 0
        val total = summary?.optInt("total") ?: 0
        val best = summary?.optInt("bestStreak") ?: 0
        val brand = androidx.compose.ui.graphics.Color(0xFF7C5CFC)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(androidx.compose.ui.graphics.Color(0xFF101014)))
                .cornerRadius(20.dp)
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
                    color = ColorProvider(androidx.compose.ui.graphics.Color(0xFF9CA3AF)),
                    fontSize = 13.sp
                )
            )
            Spacer(modifier = GlanceModifier.height(10.dp))
            Text(
                text = "🔥 $best best streak",
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            )
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
