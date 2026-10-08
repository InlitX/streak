package com.streak.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.unit.ColorProvider
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

private const val FALLBACK_COLOR = 0xFF7C3AED.toInt()
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2
private const val WEEK_MIN_HEIGHT = 300f
private const val CHIP_DP = 52f
private const val CHIP_GAP = 5f

private data class Scale(
    val pad: Float,
    val title: Float,
    val subtitle: Float,
    val ring: Float,
    val ringStroke: Float,
    val ringText: Float,
    val row: Float,
    val inset: Float,
    val icon: Float,
    val iconGap: Float,
    val name: Float,
    val button: Float,
    val gap: Float,
)

private val ROOMY = Scale(14f, 20f, 11.5f, 42f, 4.2f, 12f, 48f, 10f, 28f, 10f, 14f, 32f, 6f)
private val SNUG = Scale(12f, 17f, 10.5f, 34f, 3.6f, 10.5f, 40f, 8f, 22f, 8f, 12.5f, 26f, 5f)

class TodayWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            currentState(GlanceWidgets.REVISION)
            val style = WidgetStyle.loadFor(context, appWidgetId)
            WidgetSurface(style, radius = 22.dp) { Body(context, style, appWidgetId) }
        }
    }

    @Composable
    private fun Body(context: Context, style: WidgetStyle, appWidgetId: Int) {
        val data = WidgetPayload.forWidget(context, appWidgetId)
        val summary = data?.optJSONObject("summary")
        val done = summary?.optInt("doneToday") ?: 0
        val total = summary?.optInt("total") ?: 0
        val size = LocalSize.current
        val scale = if (size.width.value < 200f) SNUG else ROOMY
        val inner = size.width.value - scale.pad * 2
        val density = WidgetDraw.density(context)

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(scale.pad.dp)
                .clickable(actionStartActivity<MainActivity>()),
        ) {
            Header(context, style, scale, density, done, total)
            Spacer(GlanceModifier.height(10.dp))
            val habits = data?.optJSONArray("habits")
            val due = habits?.let(::dueToday).orEmpty()
            if (due.isEmpty()) {
                EmptyNote(
                    when {
                        data == null -> WidgetText.get(context, "no_data", "No data yet\nOpen Streak to sync")
                        habits == null || habits.length() == 0 ->
                            WidgetText.get(context, "no_habits", "No habits yet\nTap to open Streak")
                        else -> WidgetText.get(context, "todos_empty", "Nothing left for today")
                    },
                    style,
                )
            } else {
                if (size.height.value >= WEEK_MIN_HEIGHT && scale == ROOMY) {
                    Week(context, style, data, inner, density)
                    Spacer(GlanceModifier.height(12.dp))
                }
                LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    items(due.size) { i -> HabitRow(context, style, scale, inner, density, due[i]) }
                }
            }
        }
    }

    @Composable
    private fun Header(context: Context, style: WidgetStyle, scale: Scale, density: Float, done: Int, total: Int) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                val title = WidgetText.get(context, "today", "Today")
                Drawn(WidgetDraw.text(context, title, scale.title, style.content, 800), density, title)
                if (total > 0) {
                    val line = WidgetText.format(
                        context, "today_done", "$done of $total done",
                        "{done}" to done.toString(), "{total}" to total.toString(),
                    )
                    Drawn(
                        WidgetDraw.text(context, line, scale.subtitle, style.content.copy(alpha = 0.6f), 600),
                        density,
                        line,
                    )
                }
            }
            if (total > 0) {
                Drawn(
                    WidgetDraw.ring(
                        context, done / total.toFloat(), scale.ring, scale.ringStroke,
                        style.content, "$done/$total", scale.ringText,
                    ),
                    density,
                    "$done/$total",
                )
            }
        }
    }

    @Composable
    private fun Week(context: Context, style: WidgetStyle, data: JSONObject?, inner: Float, density: Float) {
        val days = data?.optJSONArray("days")
        val width = (inner - CHIP_GAP * (WidgetPayload.WEEK - 1)) / WidgetPayload.WEEK
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            for (day in 0 until WidgetPayload.WEEK) {
                val info = days?.optJSONObject(day)
                val label = info?.optString("short").orEmpty()
                    .ifEmpty { info?.optString("label").orEmpty() }
                if (day > 0) Spacer(GlanceModifier.width(CHIP_GAP.dp))
                Drawn(
                    WidgetDraw.chip(context, width, CHIP_DP, kindOf(data, day), label, style.content, progressOf(data, day)),
                    density,
                    label,
                )
            }
        }
    }

    private fun tally(data: JSONObject?, day: Int): Pair<Int, Int> {
        val habits = data?.optJSONArray("habits") ?: return 0 to 0
        var due = 0
        var done = 0
        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            if (habit.optBoolean("tracking", false)) continue
            val scheduled = habit.optJSONArray("scheduled")
            if (scheduled != null && !scheduled.optBoolean(day, false)) continue
            due++
            if (habit.optJSONArray("completions")?.optBoolean(day, false) == true) done++
        }
        return due to done
    }

    private fun progressOf(data: JSONObject?, day: Int): Float {
        val (due, done) = tally(data, day)
        return if (due == 0) 0f else done / due.toFloat()
    }

    private fun kindOf(data: JSONObject?, day: Int): DayKind {
        val (due, done) = tally(data, day)
        return when {
            day == WidgetPayload.TODAY -> DayKind.TODAY
            due == 0 -> DayKind.REST
            done == due -> DayKind.DONE
            else -> DayKind.MISSED
        }
    }

    private fun dueToday(habits: JSONArray): List<JSONObject> =
        (0 until habits.length())
            .mapNotNull { habits.optJSONObject(it) }
            .filter { it.optJSONArray("scheduled")?.optBoolean(WidgetPayload.TODAY, true) != false }

    @Composable
    private fun HabitRow(
        context: Context,
        style: WidgetStyle,
        scale: Scale,
        inner: Float,
        density: Float,
        habit: JSONObject,
    ) {
        val color = style.shown(Color(habit.optInt("color", FALLBACK_COLOR)))
        val kind = habit.optInt("kind", 0)
        val target = habit.optDouble("perDayTarget", 1.0).coerceAtLeast(1.0)
        val today = WidgetPayload.TODAY
        val count = habit.optJSONArray("counts")?.optDouble(today, 0.0) ?: 0.0
        val done = habit.optJSONArray("completions")?.optBoolean(today, false) == true
        val quantified = kind == KIND_QUANTITATIVE || target > 1
        val format: (Double) -> String =
            if (habit.optBoolean("clock", false)) WidgetText::clock else WidgetText::amount
        val streak = habit.optInt("streak", 0)
        val name = habit.optString("name")
        val room = inner - scale.inset * 2 - scale.icon - scale.iconGap - 6f - scale.button

        Column(modifier = GlanceModifier.fillMaxWidth()) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(scale.row.dp)
                    .cornerRadius(16.dp)
                    .background(ColorProvider(style.content.copy(alpha = 0.07f)))
                    .padding(horizontal = scale.inset.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                HabitIcon(habit, color, scale.icon)
                Spacer(GlanceModifier.width(scale.iconGap.dp))
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Drawn(WidgetDraw.text(context, name, scale.name, style.content, 650, room), density, name)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Glyph(R.drawable.widget_flame_3d, 11.dp)
                        Spacer(GlanceModifier.width(3.dp))
                        val line = buildString {
                            append(if (streak > 999) "999+" else streak.toString())
                            if (quantified) append("  ·  ${format(count)}/${format(target)}")
                        }
                        Drawn(
                            WidgetDraw.text(context, line, 11f, style.content.copy(alpha = 0.6f), 650, room - 14f),
                            density,
                            line,
                        )
                    }
                }
                Spacer(GlanceModifier.width(6.dp))
                val button = when {
                    kind == KIND_NEGATIVE && count > 0 -> ButtonKind.RELAPSE
                    kind == KIND_NEGATIVE || done -> ButtonKind.DONE
                    kind == KIND_QUANTITATIVE -> ButtonKind.AMOUNT
                    else -> ButtonKind.TODO
                }
                Box(
                    modifier = GlanceModifier
                        .size(scale.button.dp)
                        .clickable(
                            actionSendBroadcast(
                                WidgetActionReceiver.intent(
                                    context,
                                    habit.optString("id"),
                                    WidgetPayload.todayKey(context),
                                ),
                            ),
                        ),
                ) {
                    Drawn(
                        WidgetDraw.button(
                            context, scale.button, color, button,
                            (count / target).toFloat(), style.content,
                        ),
                        density,
                    )
                }
            }
            Spacer(GlanceModifier.height(scale.gap.dp))
        }
    }

    @Composable
    private fun HabitIcon(habit: JSONObject, color: Color, size: Float) {
        val bitmap = TodayIcons.load(habit.optString("iconPath"))
        Box(modifier = GlanceModifier.size(size.dp), contentAlignment = Alignment.Center) {
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    colorFilter = if (habit.optBoolean("iconTintable", true)) {
                        ColorFilter.tint(ColorProvider(color))
                    } else {
                        null
                    },
                    modifier = GlanceModifier.size(size.dp),
                )
            }
        }
    }
}

object TodayIcons {
    private val cache = HashMap<String, Bitmap>()

    fun load(path: String): Bitmap? {
        if (path.isEmpty()) return null
        val file = File(path)
        if (!file.exists()) return null
        val key = "$path:${file.lastModified()}"
        synchronized(cache) { cache[key]?.let { return it } }
        val bitmap = try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 128) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (e: Exception) {
            null
        } ?: return null
        synchronized(cache) {
            if (cache.size > 48) cache.clear()
            cache[key] = bitmap
        }
        return bitmap
    }
}
