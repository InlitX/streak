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

private val dangerColor = androidx.compose.ui.graphics.Color(0xFFEF4444)

// Mirrors HabitKind in lib/features/habits/data/habit.dart.
private const val KIND_POSITIVE = 0
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2

class TodayWidget : GlanceAppWidget() {

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
        WidgetSurface(style) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
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
                    color = ColorProvider(style.content),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.height(10.dp))

            if (habits != null && habits.length() > 0) {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    items(habits.length()) { i ->
                        Row(style, habits.getJSONObject(i))
                    }
                }
            } else {
                Text(
                    text = "Open Streak to sync",
                    style = TextStyle(
                        color = ColorProvider(style.muted),
                        fontSize = 13.sp
                    )
                )
            }
        }
        }
    }

    @Composable
    private fun Row(style: WidgetStyle, habit: JSONObject) {
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val color = androidx.compose.ui.graphics.Color(colorInt)
        val kind = habit.optInt("kind", KIND_POSITIVE)
        val perDayTarget = habit.optInt("perDayTarget", 1).coerceAtLeast(1)
        val incrementAmount = habit.optInt("incrementAmount", 1)
        val counts = habit.optJSONArray("counts")
        val todayCount = if (counts != null && counts.length() == 7) counts.optInt(6, 0) else 0
        val completions = habit.optJSONArray("completions")
        val doneToday = completions != null && completions.length() == 7 &&
            completions.getBoolean(6)

        val action = when (kind) {
            KIND_NEGATIVE -> "relapse"
            KIND_QUANTITATIVE -> "progress"
            else -> "toggle"
        }
        val boxColor: androidx.compose.ui.graphics.Color
        val icon: String
        when (kind) {
            KIND_NEGATIVE -> {
                boxColor = if (todayCount > 0) dangerColor else color.copy(alpha = 0.18f)
                icon = if (todayCount > 0) "✕" else ""
            }
            KIND_QUANTITATIVE -> {
                val ratio = (todayCount.toFloat() / perDayTarget).coerceIn(0f, 1f)
                boxColor = color.copy(alpha = 0.25f + 0.75f * ratio)
                icon = "+"
            }
            else -> {
                boxColor = if (doneToday) color else color.copy(alpha = 0.18f)
                icon = if (doneToday) "✓" else ""
            }
        }

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = name,
                    style = TextStyle(
                        color = ColorProvider(style.content),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    maxLines = 1
                )
                if (kind == KIND_QUANTITATIVE) {
                    Text(
                        text = "$todayCount/$perDayTarget",
                        style = TextStyle(
                            color = ColorProvider(style.muted),
                            fontSize = 11.sp
                        )
                    )
                }
            }
            Box(
                modifier = GlanceModifier
                    .size(28.dp)
                    .cornerRadius(9.dp)
                    .background(ColorProvider(boxColor))
                    .clickable(
                        onClick = actionRunCallback<ToggleHabitAction>(
                            parameters = actionParametersOf(
                                ActionParameters.Key<String>("habitId") to habitId,
                                ActionParameters.Key<Int>("dayIndex") to 6,
                                ActionParameters.Key<String>("action") to action,
                                ActionParameters.Key<Int>("delta") to incrementAmount
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (icon.isNotEmpty()) {
                    Text(
                        text = icon,
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
