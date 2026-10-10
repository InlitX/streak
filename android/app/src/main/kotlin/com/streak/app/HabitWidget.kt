package com.streak.app

import android.content.Context
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
import androidx.glance.layout.ContentScale
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
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.roundToInt

private const val FALLBACK_COLOR = 0xFF7C3AED.toInt()
private const val KIND_NEGATIVE = 1
private const val KIND_QUANTITATIVE = 2
private const val TODAY_INDEX = 6

private const val PAD = 14f
private const val HEADER = 44f
private const val BAR_H = 16f
private const val BAR_GAP = 5f
private const val LETTER_ROW = 22f
private const val LIST_GAP = 6f
private const val ROW = 40f
private const val ROW_GAP = 5f
private const val ICON = 20f
private const val RIGHT_INSET = 8f

private data class Grid(val inner: Float, val name: Float, val cell: Float, val dot: Float, val first: Int, val span: Int)

private fun series(habit: JSONObject, name: String, day: Int): Any? =
    if (day >= 0) {
        habit.optJSONArray(name)?.opt(day)
    } else {
        habit.optJSONObject("earlier")?.optJSONArray(name)?.opt(day + WidgetPayload.EARLIER)
    }

private fun dayAt(data: JSONObject, day: Int): JSONObject? =
    if (day >= 0) {
        data.optJSONArray("days")?.optJSONObject(day)
    } else {
        data.optJSONArray("earlierDays")?.optJSONObject(day + WidgetPayload.EARLIER)
    }

class HabitWidget : GlanceAppWidget() {

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
        val habits = data?.optJSONArray("habits")
        val days = data?.optJSONArray("days")
        val size = LocalSize.current
        val density = WidgetDraw.density(context)
        if (data == null || habits == null || days == null || habits.length() == 0) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(PAD.dp).clickable(actionStartActivity<MainActivity>())) {
                EmptyNote(
                    WidgetText.get(
                        context,
                        if (data == null) "no_data" else "no_habits",
                        if (data == null) "No data yet\nOpen Streak to sync" else "No habits yet\nTap to open Streak",
                    ),
                    style,
                )
            }
            return
        }
        val span = WidgetConfig.span(context, appWidgetId)
        val first = if (span > 7) TODAY_INDEX - span + 1 else data.optInt("weekOffset", 0).coerceIn(0, maxOf(0, days.length() - 7))
        val inner = size.width.value - PAD * 2
        val name = inner * 0.40f
        val cell = (inner - name - RIGHT_INSET) / span
        val grid = Grid(inner, name, cell, minOf(22f, cell - 4f), first, span)
        val pastFirst = data.optBoolean("pastFirst", false)
        val look = WidgetConfig.look(context, appWidgetId)
        val keys = List(span) {
            dayAt(data, first + it)?.optString("key") ?: WidgetPayload.todayKey(context)
        }

        val last = habits.length() - 1
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(start = PAD.dp, top = PAD.dp, bottom = PAD.dp)
                .clickable(actionStartActivity<MainActivity>()),
        ) {
            val edge = GlanceModifier.fillMaxWidth().padding(end = PAD.dp)
            val header = HEADER * WidgetDraw.textScale(context)
            Box(modifier = edge.height((header + LIST_GAP).dp)) {
                val top = BAR_H + BAR_GAP + (LETTER_ROW - grid.dot) / 2f - 3f
                Band(context, style, grid, top, header + LIST_GAP - top, openTop = false, openBottom = true)
                Header(context, style, grid, density, habits, data, header, look.header)
            }
            LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                items(habits.length()) { index ->
                    habits.optJSONObject(index)?.let {
                        Box(edge) { HabitRow(context, style, grid, density, it, keys, index == last, pastFirst, look) }
                    }
                }
            }
        }
    }

    @Composable
    private fun Band(
        context: Context,
        style: WidgetStyle,
        grid: Grid,
        top: Float,
        height: Float,
        openTop: Boolean,
        openBottom: Boolean,
    ) {
        val column = TODAY_INDEX - grid.first
        if (column !in 0 until grid.span) return
        val width = grid.dot + 6f
        val left = grid.name + grid.cell * column + (grid.cell - width) / 2f
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Spacer(GlanceModifier.height(top.dp))
            Row {
                Spacer(GlanceModifier.width(left.dp))
                Image(
                    provider = ImageProvider(WidgetDraw.band(context, width, height, style.content, openTop, openBottom)),
                    contentDescription = null,
                    contentScale = ContentScale.FillBounds,
                    modifier = GlanceModifier.width(width.dp).height(height.dp),
                )
            }
        }
    }

    @Composable
    private fun Header(
        context: Context,
        style: WidgetStyle,
        grid: Grid,
        density: Float,
        habits: JSONArray,
        data: JSONObject,
        height: Float,
        titled: Boolean,
    ) {
        var due = 0
        var done = 0
        val ratios = List(grid.span) { column ->
            val (d, k) = tally(habits, grid.first + column)
            due += d
            done += k
            if (d == 0 || grid.first + column > TODAY_INDEX) 0f else k / d.toFloat()
        }
        Row(modifier = GlanceModifier.fillMaxWidth().height(height.dp)) {
            Column(modifier = GlanceModifier.width(grid.name.dp)) {
                if (!titled) return@Column
                val title = if (grid.span > 7) {
                    WidgetText.format(context, "last_days", "Last ${grid.span} days", "{count}" to grid.span.toString())
                } else {
                    WidgetText.get(context, "this_week", "This week")
                }
                val size = WidgetDraw.fit(context, title, 19f, 11f, 800, grid.name - 4f)
                Drawn(WidgetDraw.text(context, title, size, style.content, 800, grid.name - 4f), density, title)
                if (due > 0) {
                    val line = WidgetText.format(
                        context, "week_done", "$done of $due",
                        "{done}" to done.toString(), "{total}" to due.toString(),
                    ) + "  ·  ${(done * 100f / due).roundToInt()}%"
                    Drawn(
                        WidgetDraw.text(context, line, 11.5f, style.content.copy(alpha = 0.6f), 600, grid.name - 4f),
                        density,
                        line,
                    )
                }
            }
            Column {
                Row {
                    for (column in 0 until grid.span) {
                        Box(modifier = GlanceModifier.width(grid.cell.dp), contentAlignment = Alignment.Center) {
                            Drawn(WidgetDraw.bar(context, 5f, BAR_H, ratios[column], style.content), density)
                        }
                    }
                }
                Spacer(GlanceModifier.height(BAR_GAP.dp))
                Row {
                    for (column in 0 until grid.span) {
                        val day = dayAt(data, grid.first + column)
                        val letter = day?.optString("label").orEmpty()
                        Box(
                            modifier = GlanceModifier.width(grid.cell.dp).height(LETTER_ROW.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            if (grid.first + column == TODAY_INDEX) {
                                Drawn(WidgetDraw.pill(context, grid.dot, letter, style.content), density, letter)
                            } else {
                                Drawn(
                                    WidgetDraw.text(context, letter, 10.5f, style.content.copy(alpha = 0.5f), 700),
                                    density,
                                    letter,
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private fun tally(habits: JSONArray, day: Int): Pair<Int, Int> {
        var due = 0
        var done = 0
        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            if (habit.optBoolean("tracking", false)) continue
            if (habit.has("scheduled") && series(habit, "scheduled", day) != true) continue
            due++
            if (series(habit, "completions", day) == true) done++
        }
        return due to done
    }

    @Composable
    private fun HabitRow(
        context: Context,
        style: WidgetStyle,
        grid: Grid,
        density: Float,
        habit: JSONObject,
        keys: List<String>,
        last: Boolean,
        pastFirst: Boolean,
        look: WidgetLook,
    ) {
        val habitId = habit.optString("id")
        val color = style.shown(Color(habit.optInt("color", FALLBACK_COLOR)))
        val kind = habit.optInt("kind", 0)
        val target = habit.optDouble("perDayTarget", 1.0).coerceAtLeast(1.0)
        val quantified = kind == KIND_QUANTITATIVE || target > 1
        val streak = habit.optInt("streak", 0)
        val name = habit.optString("name")
        val room = grid.name - 9f - (if (look.icons) ICON + 8f else 0f) - 4f

        Box(modifier = GlanceModifier.fillMaxWidth().height((ROW + ROW_GAP).dp)) {
            Band(
                context, style, grid, 0f,
                if (last) ROW / 2f + grid.dot / 2f + 3f else ROW + ROW_GAP,
                openTop = true, openBottom = !last,
            )
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(ROW.dp)
                    .cornerRadius(15.dp)
                    .background(ColorProvider(style.content.copy(alpha = if (look.cards) 0.07f else 0f))),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Spacer(GlanceModifier.width(9.dp))
                if (look.icons) {
                    HabitIcon(habit, color)
                    Spacer(GlanceModifier.width(8.dp))
                }
                Column(modifier = GlanceModifier.width(room.dp)) {
                    Drawn(WidgetDraw.text(context, name, 12.5f, style.content, 650, room), density, name)
                    if (look.details) Row(verticalAlignment = Alignment.CenterVertically) {
                        Glyph(R.drawable.widget_flame_3d, 10.dp)
                        Spacer(GlanceModifier.width(3.dp))
                        Drawn(
                            WidgetDraw.text(
                                context, if (streak > 999) "999+" else streak.toString(),
                                10f, style.content.copy(alpha = 0.6f), 650,
                            ),
                            density,
                        )
                    }
                }
                Spacer(GlanceModifier.width(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    for (column in 0 until grid.span) {
                        val i = grid.first + column
                        val completed = series(habit, "completions", i) == true
                        val count = (series(habit, "counts", i) as? Number)?.toDouble() ?: 0.0
                        val planned = series(habit, "scheduled", i) != false
                        val future = i > TODAY_INDEX
                        val mark = when {
                            future -> if (planned) WeekMark.EMPTY else WeekMark.OFF
                            kind == KIND_NEGATIVE && count > 0 -> WeekMark.RELAPSE
                            completed -> WeekMark.DONE
                            quantified && count > 0 -> WeekMark.PART
                            !planned -> WeekMark.OFF
                            i == TODAY_INDEX -> WeekMark.TODAY
                            else -> WeekMark.MISSED
                        }
                        val cell = GlanceModifier.width(grid.cell.dp).height(ROW.dp)
                        val key = keys.getOrElse(column) { WidgetPayload.todayKey(context) }
                        Box(
                            modifier = when {
                                future -> cell
                                i < TODAY_INDEX && pastFirst -> cell.clickable(openPageAction(context, "day:$habitId:$key"))
                                else -> cell.clickable(actionSendBroadcast(WidgetActionReceiver.intent(context, habitId, key)))
                            },
                            contentAlignment = Alignment.Center,
                        ) {
                            Drawn(
                                WidgetDraw.dot(context, grid.dot, color, mark, (count / target).toFloat(), style.content),
                                density,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun HabitIcon(habit: JSONObject, color: Color) {
        val bitmap = TodayIcons.load(habit.optString("iconPath"))
        Box(modifier = GlanceModifier.size(ICON.dp), contentAlignment = Alignment.Center) {
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    colorFilter = if (habit.optBoolean("iconTintable", true)) {
                        ColorFilter.tint(ColorProvider(color))
                    } else {
                        null
                    },
                    modifier = GlanceModifier.size(ICON.dp),
                )
            }
        }
    }
}
