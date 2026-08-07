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
import androidx.glance.appwidget.action.actionSendBroadcast
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

private const val KIND_POSITIVE = 0
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2

private const val LABEL_WIDTH_DP = 104
private const val RATE_BAR_DP = 44

class HabitWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
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
        val context = androidx.glance.LocalContext.current
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
                        Box(
                            modifier = GlanceModifier.width(LABEL_WIDTH_DP.dp),
                            contentAlignment = Alignment.CenterStart
                        ) {
                            CompletionRate(style, data.optJSONObject("summary"))
                        }
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
                    EmptyState(style, WidgetText.get(context, "no_habits", "No habits yet\nTap to open Streak"))
                }
            } else {
                EmptyState(style, WidgetText.get(context, "no_data", "No data yet\nOpen Streak to sync"))
            }
        }
    }

    @Composable
    private fun CompletionRate(style: WidgetStyle, summary: JSONObject?) {
        val total = summary?.optInt("total", 0) ?: 0
        if (total <= 0) return
        val done = summary?.optInt("doneToday", 0) ?: 0
        val ratio = (done.toFloat() / total).coerceIn(0f, 1f)

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "${(ratio * 100).toInt()}%",
                style = TextStyle(
                    color = ColorProvider(style.content),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.width(6.dp))
            Box(
                modifier = GlanceModifier
                    .width(RATE_BAR_DP.dp)
                    .height(4.dp)
                    .cornerRadius(2.dp)
                    .background(ColorProvider(style.cell)),
                contentAlignment = Alignment.CenterStart
            ) {
                if (ratio > 0f) {
                    Box(
                        modifier = GlanceModifier
                            .width((RATE_BAR_DP * ratio).dp.coerceAtLeast(4.dp))
                            .height(4.dp)
                            .cornerRadius(2.dp)
                            .background(ColorProvider(brandColor)),
                        content = {}
                    )
                }
            }
        }
    }

    @Composable
    private fun HabitRow(style: WidgetStyle, habit: JSONObject) {
        val context = androidx.glance.LocalContext.current
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val color = androidx.compose.ui.graphics.Color(colorInt)
        val completions = habit.getJSONArray("completions")
        val kind = habit.optInt("kind", KIND_POSITIVE)
        val perDayTarget = habit.optDouble("perDayTarget", 1.0).coerceAtLeast(1.0)
        val counts = habit.optJSONArray("counts")
        val streak = habit.optInt("streak", 0)
        val quantified = kind == KIND_QUANTITATIVE || perDayTarget > 1

        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = GlanceModifier.width(LABEL_WIDTH_DP.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
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
                StreakBadge(streak, color, style)
            }

            Spacer(modifier = GlanceModifier.width(8.dp))

            Row(
                modifier = GlanceModifier.defaultWeight(),
                horizontalAlignment = Alignment.End,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (i in 0 until 7) {
                    val isCompleted = if (i < completions.length()) completions.getBoolean(i) else false
                    val count =
                        if (counts != null && i < counts.length()) counts.optDouble(i, 0.0) else 0.0
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
                                    onClick = actionSendBroadcast(
                                        WidgetActionReceiver.intent(context, habitId, i)
                                    )
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            when {
                                kind == KIND_NEGATIVE -> if (count > 0) {
                                    BreachMark(style)
                                } else {
                                    CompletionIndicator(isCompleted = isCompleted, color = color)
                                }
                                quantified -> ValueIndicator(
                                    count = count,
                                    ratio = (count / perDayTarget).toFloat(),
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
    private fun BreachMark(style: WidgetStyle) {
        Text(
            text = "✕",
            style = TextStyle(
                color = ColorProvider(style.content),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }

    @Composable
    private fun ValueIndicator(
        count: Double,
        ratio: Float,
        color: androidx.compose.ui.graphics.Color
    ) {
        if (count <= 0) {
            CompletionIndicator(isCompleted = false, color = color)
            return
        }
        val clamped = ratio.coerceIn(0f, 1f)
        val label = WidgetText.compact(count)
        Box(
            modifier = GlanceModifier
                .size(20.dp)
                .background(ColorProvider(color.copy(alpha = 0.35f + 0.65f * clamped)))
                .cornerRadius(7.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = label,
                style = TextStyle(
                    color = ColorProvider(
                        if (clamped >= 0.6f) androidx.compose.ui.graphics.Color.White else color
                    ),
                    fontSize = when {
                        label.length > 3 -> 7.sp
                        label.length > 2 -> 8.sp
                        else -> 10.sp
                    },
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
        }
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
