package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
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
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.unit.ColorProvider
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.ContentScale
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONObject

private val brandColor = androidx.compose.ui.graphics.Color(0xFF6C5CE7)
private val dangerColor = androidx.compose.ui.graphics.Color(0xFFEF4444)

// Mirrors HabitKind in lib/features/habits/data/habit.dart.
private const val KIND_POSITIVE = 0
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2

class HabitWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        // Read inside composition: update() recomposes without re-running this.
        provideContent {
            currentState<HomeWidgetGlanceState>()
            WidgetContent(context, WidgetStyle.loadFor(context, appWidgetId))
        }
    }

    @Composable
    private fun WidgetContent(context: Context, style: WidgetStyle) {
        val data = loadWidgetData(context)
        WidgetSurface(style) {
            WidgetBody(style, data)
        }
    }

    @Composable
    private fun WidgetBody(style: WidgetStyle, data: JSONObject?) {
        val modifier = GlanceModifier
            .fillMaxSize()
            .padding(16.dp)
            .clickable(actionStartActivity<MainActivity>())

        Column(modifier = modifier) {
            if (data != null) {
                val habits = data.optJSONArray("habits")
                val days = data.optJSONArray("days")

                if (habits != null && days != null) {
                    Row(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                    ) {
                        Spacer(modifier = GlanceModifier.width(90.dp))
                        Spacer(modifier = GlanceModifier.width(8.dp))
                        Row(
                            modifier = GlanceModifier.defaultWeight(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            for (i in 0 until 7) {
                                if (i < days.length()) {
                                    val day = days.getJSONObject(i)
                                    val label = day.getString("label")
                                    val isToday = day.getBoolean("isToday")
                                    Box(
                                        modifier = GlanceModifier.defaultWeight(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = label,
                                            style = TextStyle(
                                                color = ColorProvider(
                                                    if (isToday) brandColor else style.muted
                                                ),
                                                fontSize = 14.sp,
                                                fontWeight = FontWeight.Bold
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    LazyColumn(
                        modifier = GlanceModifier.fillMaxWidth().defaultWeight()
                    ) {
                        items(habits.length()) { habitIndex ->
                            HabitRow(style, habits.getJSONObject(habitIndex))
                        }
                    }
                } else {
                    EmptyState(style, "No habits yet\nTap to open Streak")
                }
            } else {
                EmptyState(style, "No data yet\nOpen Streak to sync")
            }
        }
    }

    @Composable
    private fun HabitRow(style: WidgetStyle, habit: JSONObject) {
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val color = androidx.compose.ui.graphics.Color(colorInt)
        val completions = habit.getJSONArray("completions")
        val kind = habit.optInt("kind", KIND_POSITIVE)
        val perDayTarget = habit.optInt("perDayTarget", 1).coerceAtLeast(1)
        val incrementAmount = habit.optInt("incrementAmount", 1)
        val counts = habit.optJSONArray("counts")
        val action = when (kind) {
            KIND_NEGATIVE -> "relapse"
            KIND_QUANTITATIVE -> "progress"
            else -> "toggle"
        }

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier.width(90.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(
                    text = name,
                    style = TextStyle(
                        color = ColorProvider(style.content),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    ),
                    maxLines = 1
                )
            }

            Spacer(modifier = GlanceModifier.width(8.dp))

            Row(
                modifier = GlanceModifier.defaultWeight(),
                horizontalAlignment = Alignment.End,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (i in 0 until 7) {
                    val isCompleted = if (i < completions.length()) completions.getBoolean(i) else false
                    val count = if (counts != null && i < counts.length()) counts.optInt(i, 0) else 0
                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .padding(4.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Box(
                            modifier = GlanceModifier
                                .size(24.dp)
                                .cornerRadius(12.dp)
                                .clickable(
                                    onClick = actionRunCallback<ToggleHabitAction>(
                                        parameters = actionParametersOf(
                                            ActionParameters.Key<String>("habitId") to habitId,
                                            ActionParameters.Key<Int>("dayIndex") to i,
                                            ActionParameters.Key<String>("action") to action,
                                            ActionParameters.Key<Int>("delta") to incrementAmount
                                        )
                                    )
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            when (kind) {
                                KIND_NEGATIVE -> CompletionIndicator(
                                    isCompleted = count > 0,
                                    color = if (count > 0) dangerColor else color
                                )
                                KIND_QUANTITATIVE -> ProgressIndicator(
                                    ratio = count.toFloat() / perDayTarget,
                                    color = color
                                )
                                else -> CompletionIndicator(isCompleted = isCompleted, color = color)
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun CompletionIndicator(isCompleted: Boolean, color: androidx.compose.ui.graphics.Color) {
        val size = if (isCompleted) 18.dp else 8.dp
        val radius = if (isCompleted) 6.dp else 10.dp
        val alpha = if (isCompleted) 1f else 0.35f
        Box(
            modifier = GlanceModifier
                .size(size)
                .background(ColorProvider(color.copy(alpha = alpha)))
                .cornerRadius(radius),
            content = {}
        )
    }

    @Composable
    private fun ProgressIndicator(ratio: Float, color: androidx.compose.ui.graphics.Color) {
        val clamped = ratio.coerceIn(0f, 1f)
        val size = (8 + 10 * clamped).dp
        val alpha = if (clamped > 0f) (0.4f + 0.6f * clamped) else 0.35f
        Box(
            modifier = GlanceModifier
                .size(size)
                .background(ColorProvider(color.copy(alpha = alpha)))
                .cornerRadius(size / 2),
            content = {}
        )
    }

    @Composable
    private fun EmptyState(style: WidgetStyle, message: String) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(top = 24.dp),
            contentAlignment = Alignment.TopCenter
        ) {
            Text(
                text = message,
                style = TextStyle(
                    color = ColorProvider(style.muted),
                    fontSize = 13.sp
                )
            )
        }
    }

    private fun loadWidgetData(context: Context): JSONObject? {
        return try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val json = prefs.getString("habits_data", null)
            if (json != null) JSONObject(json) else null
        } catch (e: Exception) {
            null
        }
    }
}

class ToggleHabitAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val habitId = parameters[ActionParameters.Key<String>("habitId")]
        val dayIndex = parameters[ActionParameters.Key<Int>("dayIndex")]
        val action = parameters[ActionParameters.Key<String>("action")] ?: "toggle"
        val delta = parameters[ActionParameters.Key<Int>("delta")] ?: 1
        if (habitId != null && dayIndex != null) {
            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse(
                    "streak://toggleHabit?habitId=$habitId&dayIndex=$dayIndex" +
                        "&action=$action&delta=$delta"
                )
            )
            backgroundIntent.send()
        }
    }
}
