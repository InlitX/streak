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
import androidx.glance.currentState
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import androidx.glance.layout.*
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.text.FontWeight
import androidx.glance.appwidget.cornerRadius
import androidx.glance.action.clickable
import androidx.glance.action.actionStartActivity
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.unit.ColorProvider
import org.json.JSONObject

class TodayWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context) }
    }

    @Composable
    private fun Content(context: Context) {
        val data = loadData(context)
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ColorProvider(androidx.compose.ui.graphics.Color(0xFF101014)))
                .cornerRadius(20.dp)
                .padding(16.dp)
                .clickable(actionStartActivity<MainActivity>())
        ) {
            val habits = data?.optJSONArray("habits")
            val summary = data?.optJSONObject("summary")
            val done = summary?.optInt("doneToday") ?: 0
            val total = summary?.optInt("total") ?: 0

            Text(
                text = "Today  $done/$total",
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.height(10.dp))

            if (habits != null && habits.length() > 0) {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    items(habits.length()) { i ->
                        Row(habits.getJSONObject(i))
                    }
                }
            } else {
                Text(
                    text = "Open Streak to sync",
                    style = TextStyle(
                        color = ColorProvider(androidx.compose.ui.graphics.Color(0xFF808080)),
                        fontSize = 13.sp
                    )
                )
            }
        }
    }

    @Composable
    private fun Row(habit: JSONObject) {
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val completions = habit.optJSONArray("completions")
        val doneToday = completions != null && completions.length() == 7 &&
            completions.getBoolean(6)
        val color = androidx.compose.ui.graphics.Color(colorInt)

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = name,
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                ),
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight()
            )
            Box(
                modifier = GlanceModifier
                    .size(28.dp)
                    .cornerRadius(9.dp)
                    .background(
                        ColorProvider(if (doneToday) color else color.copy(alpha = 0.18f))
                    )
                    .clickable(
                        onClick = actionRunCallback<ToggleHabitAction>(
                            parameters = actionParametersOf(
                                ActionParameters.Key<String>("habitId") to habitId,
                                ActionParameters.Key<Int>("dayIndex") to 6
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (doneToday) {
                    Text(
                        text = "✓",
                        style = TextStyle(
                            color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
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
