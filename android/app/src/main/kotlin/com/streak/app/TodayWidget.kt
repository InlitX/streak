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
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.unit.ColorProvider
import org.json.JSONObject


private const val KIND_POSITIVE = 0
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2

class TodayWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
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
                text = WidgetText.format(
                    context, "today_progress", "Today  $done/$total",
                    "{done}" to done.toString(), "{total}" to total.toString(),
                ),
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
                    text = WidgetText.get(context, "open_to_sync", "Open Streak to sync"),
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
        val context = androidx.glance.LocalContext.current
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val color = androidx.compose.ui.graphics.Color(colorInt)
        val kind = habit.optInt("kind", KIND_POSITIVE)
        val perDayTarget = habit.optDouble("perDayTarget", 1.0).coerceAtLeast(1.0)
        val counts = habit.optJSONArray("counts")
        val today = WidgetPayload.TODAY
        val todayCount =
            if (counts != null && counts.length() > today) counts.optDouble(today, 0.0) else 0.0
        val completions = habit.optJSONArray("completions")
        val doneToday = completions != null && completions.length() > today &&
            completions.optBoolean(today, false)

        val boxColor: androidx.compose.ui.graphics.Color
        val icon: String
        val iconColor: androidx.compose.ui.graphics.Color
        when (kind) {
            KIND_NEGATIVE -> {
                val breached = todayCount > 0
                boxColor = if (breached) color.copy(alpha = 0.18f) else color
                icon = if (breached) "✕" else "✓"
                iconColor = if (breached) style.content else androidx.compose.ui.graphics.Color.White
            }
            KIND_QUANTITATIVE -> {
                val ratio = (todayCount / perDayTarget).toFloat().coerceIn(0f, 1f)
                boxColor = color.copy(alpha = 0.25f + 0.75f * ratio)
                icon = "+"
                iconColor = androidx.compose.ui.graphics.Color.White
            }
            else -> {
                boxColor = if (doneToday) color else color.copy(alpha = 0.18f)
                icon = if (doneToday) "✓" else ""
                iconColor = androidx.compose.ui.graphics.Color.White
            }
        }

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = name,
                        style = TextStyle(
                            color = ColorProvider(style.content),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        ),
                        maxLines = 1,
                        modifier = GlanceModifier.defaultWeight()
                    )
                    StreakBadge(habit.optInt("streak", 0), color, style)
                }
                if (kind == KIND_QUANTITATIVE || perDayTarget > 1) {
                    Text(
                        text = "${WidgetText.amount(todayCount)}/" +
                            WidgetText.amount(perDayTarget),
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
                        onClick = actionSendBroadcast(
                            WidgetActionReceiver.intent(
                                context,
                                habitId,
                                WidgetPayload.todayKey(),
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (icon.isNotEmpty()) {
                    Text(
                        text = icon,
                        style = TextStyle(
                            color = ColorProvider(iconColor),
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
            }
        }
    }

    private fun loadData(context: Context): JSONObject? = WidgetPayload.aligned(context)
}
