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

class HabitWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            WidgetContent(context, currentState())
        }
    }

    @Composable
    private fun WidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
        val data = loadWidgetData(context)

        // Use the first habit's cover photo as the widget background if present.
        val cover = firstCover(data)
        val bitmap = loadBitmap(cover)

        Box(modifier = GlanceModifier.fillMaxSize().cornerRadius(20.dp)) {
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().cornerRadius(20.dp)
                )
                // Dark scrim keeps the grid readable over the photo.
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(ColorProvider(androidx.compose.ui.graphics.Color(0xCC000000)))
                        .cornerRadius(20.dp)
                ) {}
            }
            WidgetBody(data, opaque = bitmap == null)
        }
    }

    @Composable
    private fun WidgetBody(data: JSONObject?, opaque: Boolean) {
        val base = GlanceModifier
            .fillMaxWidth()
            .cornerRadius(20.dp)
            .padding(16.dp)
            .clickable(actionStartActivity<MainActivity>())
        val modifier = if (opaque) {
            base.background(ColorProvider(androidx.compose.ui.graphics.Color(0xFF101014)))
        } else {
            base
        }

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
                                                    if (isToday) brandColor
                                                    else androidx.compose.ui.graphics.Color(0x66808080)
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
                            HabitRow(habits.getJSONObject(habitIndex))
                        }
                    }
                } else {
                    EmptyState("No habits yet\nTap to open Streak")
                }
            } else {
                EmptyState("No data yet\nOpen Streak to sync")
            }
        }
    }

    @Composable
    private fun HabitRow(habit: JSONObject) {
        val habitId = habit.getString("id")
        val name = habit.getString("name")
        val colorInt = habit.getInt("color")
        val completions = habit.getJSONArray("completions")

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
                        color = ColorProvider(androidx.compose.ui.graphics.Color.White),
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
                                            ActionParameters.Key<Int>("dayIndex") to i
                                        )
                                    )
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            CompletionIndicator(
                                isCompleted = isCompleted,
                                color = androidx.compose.ui.graphics.Color(colorInt)
                            )
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
    private fun EmptyState(message: String) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(top = 24.dp),
            contentAlignment = Alignment.TopCenter
        ) {
            Text(
                text = message,
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color(0xFF808080)),
                    fontSize = 13.sp
                )
            )
        }
    }

    private fun firstCover(data: JSONObject?): String {
        val habits = data?.optJSONArray("habits") ?: return ""
        for (i in 0 until habits.length()) {
            val cover = habits.optJSONObject(i)?.optString("cover", "") ?: ""
            if (cover.isNotEmpty()) return cover
        }
        return ""
    }

    private fun loadBitmap(path: String): Bitmap? {
        if (path.isEmpty()) return null
        return try {
            val file = java.io.File(path)
            if (file.exists()) BitmapFactory.decodeFile(path) else null
        } catch (e: Exception) {
            null
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
        if (habitId != null && dayIndex != null) {
            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("streak://toggleHabit?habitId=$habitId&dayIndex=$dayIndex")
            )
            backgroundIntent.send()
        }
    }
}
