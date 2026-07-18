package com.streak.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
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
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.unit.ColorProvider
import org.json.JSONArray
import org.json.JSONObject

private val brandColor = androidx.compose.ui.graphics.Color(0xFF7C5CFC)
private val surfaceColor = androidx.compose.ui.graphics.Color(0xFF101014)
private val emptyCellColor = androidx.compose.ui.graphics.Color(0xFF23232B)
private val futureCellColor = androidx.compose.ui.graphics.Color(0xFF17171C)

// Over a photo, gaps use translucent white.
private val emptyOverPhotoColor = androidx.compose.ui.graphics.Color(0x33FFFFFF)
private val futureOverPhotoColor = androidx.compose.ui.graphics.Color(0x14FFFFFF)

private const val PADDING = 16f
private const val HEADER = 26f
private const val GAP = 2f

// Glance Row/Column silently render only their first 10 children.
private const val MAX_CHILDREN = 10

private class HeatmapData(
    val title: String,
    val color: androidx.compose.ui.graphics.Color,
    val cover: String,
    val levels: List<Int>
)

class HeatmapWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            // Read state or Glance renders once and never refreshes.
            currentState<HomeWidgetGlanceState>()
            // Read inside composition: update() recomposes but won't re-run provideGlance.
            val habitId = HeatmapConfig.habitOf(context, appWidgetId)
            Content(context, habitId)
        }
    }

    @Composable
    private fun Content(context: Context, habitId: String?) {
        val data = load(context, habitId)
        val bitmap = loadBitmap(data?.cover ?: "")

        Box(modifier = GlanceModifier.fillMaxSize().cornerRadius(20.dp)) {
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().cornerRadius(20.dp)
                )
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(
                            ColorProvider(androidx.compose.ui.graphics.Color(0xB3000000))
                        )
                        .cornerRadius(20.dp)
                ) {}
            }
            Body(data, overPhoto = bitmap != null, habitId = habitId)
        }
    }

    @Composable
    private fun Body(data: HeatmapData?, overPhoto: Boolean, habitId: String?) {
        val size = LocalSize.current

        val bodyHeight = size.height.value - PADDING * 2 - HEADER
        val cell = ((bodyHeight / 7f) - GAP).coerceIn(5f, 14f)
        val levels = data?.levels ?: emptyList()
        val weeks = levels.size / 7
        val columns = (((size.width.value - PADDING * 2) / (cell + GAP)).toInt())
            .coerceIn(1, if (weeks > 0) weeks else 1)

        // Whole weeks only, to keep Mondays aligned.
        val shown = levels.drop((weeks - columns).coerceAtLeast(0) * 7)

        // A per-habit widget opens that habit; "all habits" opens the app.
        val tap = if (habitId != null) {
            actionStartActivity<MainActivity>(
                actionParametersOf(ActionParameters.Key<String>("openHabitId") to habitId)
            )
        } else {
            actionStartActivity<MainActivity>()
        }
        val base = GlanceModifier
            .fillMaxSize()
            .cornerRadius(20.dp)
            .padding(PADDING.dp)
            .clickable(tap)

        Column(
            modifier = if (overPhoto) base else base.background(ColorProvider(surfaceColor)),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (shown.isEmpty()) {
                Text(
                    text = "Open Streak to sync",
                    style = TextStyle(
                        color = ColorProvider(androidx.compose.ui.graphics.Color(0xFF808080)),
                        fontSize = 13.sp
                    )
                )
                return@Column
            }

            Text(
                text = data!!.title,
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 1
            )
            Spacer(modifier = GlanceModifier.height((HEADER - 20f).dp))

            Row {
                shown.chunked(7 * MAX_CHILDREN).forEach { group ->
                    Row {
                        group.chunked(7).forEach { week ->
                            Column {
                                week.forEach { level ->
                                    Box(
                                        modifier = GlanceModifier
                                            .padding(end = GAP.dp, bottom = GAP.dp)
                                    ) {
                                        Box(
                                            modifier = GlanceModifier
                                                .size(cell.dp)
                                                .cornerRadius(2.dp)
                                                .background(
                                                    ColorProvider(
                                                        colorFor(data.color, level, overPhoto)
                                                    )
                                                )
                                        ) {}
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private fun colorFor(
        base: androidx.compose.ui.graphics.Color,
        level: Int,
        overPhoto: Boolean
    ): androidx.compose.ui.graphics.Color = when (level) {
        -1 -> if (overPhoto) futureOverPhotoColor else futureCellColor
        1 -> base.copy(alpha = 0.30f)
        2 -> base.copy(alpha = 0.52f)
        3 -> base.copy(alpha = 0.76f)
        4 -> base
        else -> if (overPhoto) emptyOverPhotoColor else emptyCellColor
    }

    private fun load(context: Context, habitId: String?): HeatmapData? {
        return try {
            val prefs = context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE
            )
            val json = prefs.getString("habits_data", null) ?: return null
            val root = JSONObject(json)

            if (habitId != null) {
                val habits = root.optJSONArray("habits")
                for (i in 0 until (habits?.length() ?: 0)) {
                    val habit = habits!!.getJSONObject(i)
                    if (habit.optString("id") == habitId) {
                        return HeatmapData(
                            habit.optString("name"),
                            androidx.compose.ui.graphics.Color(habit.getInt("color")),
                            habit.optString("cover", ""),
                            levelsOf(habit.optJSONArray("heatmap"))
                        )
                    }
                }
            }
            HeatmapData("Activity", brandColor, "", levelsOf(root.optJSONArray("heatmap")))
        } catch (e: Exception) {
            null
        }
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

    private fun levelsOf(array: JSONArray?): List<Int> {
        if (array == null) return emptyList()
        // Whole weeks only.
        val usable = array.length() / 7 * 7
        return List(usable) { array.optInt(it, 0) }
    }
}
