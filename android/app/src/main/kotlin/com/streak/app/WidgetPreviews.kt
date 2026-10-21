package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp

private data class SampleHabit(
    val name: String,
    val color: Color,
    val streak: Int,
    val button: ButtonKind,
    val fill: Float,
    val icon: Bitmap? = null,
    val tint: Boolean = true,
)

private val SAMPLE = listOf(
    SampleHabit("Read", Color(0xFF7C3AED), 38, ButtonKind.DONE, 1f),
    SampleHabit("Water", Color(0xFF38B6FF), 9, ButtonKind.AMOUNT, 0.62f),
)

private fun samples(context: Context, s: WidgetStyle): List<SampleHabit> {
    val habits = WidgetPayload.forWidget(context, AppWidgetManager.INVALID_APPWIDGET_ID)?.optJSONArray("habits")
    if (habits == null || habits.length() < SAMPLE.size) return SAMPLE
    return SAMPLE.mapIndexed { i, sample ->
        val habit = habits.optJSONObject(i) ?: return SAMPLE
        sample.copy(
            name = habit.optString("name"),
            color = s.shown(Color(habit.optInt("color", sample.color.toArgb()))),
            streak = habit.optInt("streak", 0),
            icon = TodayIcons.load(habit.optString("iconPath")),
            tint = habit.optBoolean("iconTintable", true),
        )
    }
}

@Composable
private fun SampleIcon(habit: SampleHabit, size: Float) = Box(Modifier.size(size.dp)) {
    habit.icon?.let {
        Image(
            it.asImageBitmap(),
            null,
            Modifier.size(size.dp),
            colorFilter = if (habit.tint) ColorFilter.tint(habit.color) else null,
        )
    }
}

@Composable
private fun Bmp(bitmap: Bitmap, context: Context) {
    val d = WidgetDraw.density(context)
    Image(
        bitmap.asImageBitmap(),
        null,
        Modifier.size((bitmap.width / d).dp, (bitmap.height / d).dp),
    )
}

private fun sample(context: Context, key: String, fallback: String) = WidgetText.get(context, key, fallback)

@Composable
fun FocusSample(s: WidgetStyle) {
    val context = LocalContext.current
    val side = 158f
    val label = side * 0.1f
    val pad = side * 0.11f
    Column(Modifier.fillMaxSize().padding(start = pad.dp, end = pad.dp, top = (pad * 1.5f).dp, bottom = pad.dp)) {
        Bmp(WidgetDraw.text(context, "1h 25m", side * 0.22f, s.content, 800), context)
        Bmp(WidgetDraw.text(context, sample(context, "focus_today", "Focus today"), label, s.content, 800), context)
        Spacer(Modifier.height(6.dp))
        Bmp(WidgetDraw.text(context, "${sample(context, "label_week", "Week")}  6h 40m", label * 0.85f, s.muted, 650), context)
        Bmp(WidgetDraw.text(context, "${sample(context, "label_month", "Month")}  24h", label * 0.85f, s.muted, 650), context)
    }
}

@Composable
fun StatsSample(s: WidgetStyle, art: Boolean) {
    val context = LocalContext.current
    val side = 158f
    val label = side * 0.1f
    Column(Modifier.fillMaxSize().padding((side * 0.11f).dp)) {
        Bmp(WidgetDraw.text(context, "12", side * 0.3f, s.content, 800), context)
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (!art) {
                Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(label.dp))
                Spacer(Modifier.width(4.dp))
            }
            Bmp(WidgetDraw.text(context, sample(context, "streak_days", "Streak days"), label, s.content, 800), context)
        }
    }
}

@Composable
fun TodaySample(s: WidgetStyle, look: WidgetLook = WidgetLook()) {
    val context = LocalContext.current
    val habits = remember(s.dark) { samples(context, s) }
    BoxWithConstraints(Modifier.fillMaxSize().padding(14.dp)) {
        val inner = maxWidth.value
        val room = inner - 70f - if (look.icons) 30f else 0f
        val shown = habits.filterNot { look.hideDone && it.button == ButtonKind.DONE }
        val row = if (look.compact) 29f else 40f
        val icon = if (look.compact) 17f else 22f
        val button = if (look.compact) 22f else 28f
        val nameSize = if (look.compact) 12f else 13.5f
        Column {
            if (look.header) Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Bmp(WidgetDraw.text(context, sample(context, "today", "Today"), 20f, s.content, 800), context)
                    val line = WidgetText.format(context, "today_done", "1 of 2 done", "{done}" to "1", "{total}" to "2")
                    Bmp(WidgetDraw.text(context, line, 11.5f, s.content.copy(alpha = 0.6f), 600), context)
                }
                Bmp(WidgetDraw.ring(context, 0.5f, 42f, 4.2f, s.content, "1/2", 12f), context)
            }
            if (look.header) Spacer(Modifier.height(10.dp))
            shown.forEach { habit ->
                Row(
                    Modifier.fillMaxWidth().height(row.dp).clip(RoundedCornerShape(16.dp))
                        .background(s.content.copy(alpha = if (look.cards) 0.07f else 0f)).padding(horizontal = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (look.icons) {
                        SampleIcon(habit, icon)
                        Spacer(Modifier.width(8.dp))
                    }
                    if (look.compact) Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                        Bmp(WidgetDraw.text(context, habit.name, nameSize, s.content, 650, room * 0.6f), context)
                        if (look.details) {
                            Spacer(Modifier.width(6.dp))
                            Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(10.dp))
                            Spacer(Modifier.width(3.dp))
                            Bmp(WidgetDraw.text(context, habit.streak.toString(), 10.5f, s.content.copy(alpha = 0.6f), 650), context)
                        }
                    } else Column(Modifier.weight(1f)) {
                        Bmp(WidgetDraw.text(context, habit.name, nameSize, s.content, 650, room), context)
                        if (look.details) Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(10.dp))
                            Spacer(Modifier.width(3.dp))
                            Bmp(WidgetDraw.text(context, habit.streak.toString(), 10.5f, s.content.copy(alpha = 0.6f), 650), context)
                        }
                    }
                    Bmp(WidgetDraw.button(context, button, habit.color, habit.button, habit.fill, s.content, look.round), context)
                }
                Spacer(Modifier.height(if (look.compact) 3.dp else 5.dp))
            }
        }
    }
}

@Composable
fun TodosSample(s: WidgetStyle, art: Boolean, look: WidgetLook = WidgetLook()) {
    val context = LocalContext.current
    val night = (context.resources.configuration.uiMode and
        Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    val surface = if (night) Color(0xF21C1C22) else Color(0xF7FFFFFF)
    val ink = if (night) Color(0xFFF5F5F7) else Color(0xFF16161C)
    val muted = ink.copy(alpha = if (night) 0.6f else 0.55f)
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val width = maxWidth.value
        val left = width * 0.36f
        if (art) {
            Image(
                painterResource(
                    if (s.content.luminance() < 0.5f) R.drawable.widget_todo_sticker_light
                    else R.drawable.widget_todo_sticker,
                ),
                null,
                Modifier.size(maxHeight).align(Alignment.BottomStart),
            )
        }
        Row(Modifier.fillMaxSize().padding(10.dp)) {
            Column(Modifier.width((left - 10f).dp).fillMaxHeight().padding(start = 6.dp, top = 2.dp)) {
                Bmp(WidgetDraw.text(context, sample(context, "today", "Today"), 12f, s.content.copy(alpha = 0.62f), 650), context)
                Bmp(WidgetDraw.text(context, "6", 26f, s.content, 800), context)
            }
            Column(
                Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(18.dp))
                    .background(surface).padding(horizontal = 12.dp, vertical = 9.dp),
                verticalArrangement = Arrangement.spacedBy(if (look.compact) 3.dp else 6.dp),
            ) {
                listOf("Stretch" to false, "Call mom" to true).filterNot { look.hideDone && it.second }.forEach { (title, done) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.width(3.dp).height(16.dp).clip(RoundedCornerShape(2.dp))
                                .background(if (done) ink.copy(alpha = 0.15f) else ink.copy(alpha = 0.85f)),
                        )
                        Spacer(Modifier.width(9.dp))
                        Box(Modifier.weight(1f)) {
                            Bmp(WidgetDraw.text(context, title, if (look.compact) 12.5f else 13.5f, if (done) muted else ink, 650, strike = done), context)
                        }
                        Bmp(WidgetDraw.roundCheck(context, if (look.compact) 18f else 22f, ink, done), context)
                    }
                }
            }
        }
    }
}

@Composable
fun WeekSample(s: WidgetStyle, span: Int = 7, look: WidgetLook = WidgetLook(round = true)) {
    val context = LocalContext.current
    val week = listOf("M", "T", "W", "T", "F", "S", "S")
    val letters = List(span) { week[it % 7] }
    val today = if (span > 7) span - 1 else 1
    val habits = remember(s.dark) { samples(context, s) }
    BoxWithConstraints(Modifier.fillMaxSize().padding(14.dp)) {
        val inner = maxWidth.value
        val name = inner * 0.40f
        val cell = (inner - name - 8f) / span
        val dot = minOf(if (look.compact) 18f else 22f, cell - 4f)
        val rowH = if (look.compact) 30f else 40f
        val gap = if (look.compact) 3f else 5f
        val shown = habits.withIndex().filterNot { look.hideDone && it.index == 0 }
        val title = if (span > 7) {
            WidgetText.format(context, "last_days", "Last $span days", "{count}" to span.toString())
        } else {
            sample(context, "this_week", "This week")
        }
        val bandTop = 16f + 5f + (22f - dot) / 2f - 3f
        val bandBottom = 44f + 6f + (shown.size - 1) * (rowH + gap) + rowH / 2f + dot / 2f + 3f
        if (look.band) Box(Modifier.offset(x = (name + cell * today + (cell - dot - 6f) / 2f).dp, y = bandTop.dp)) {
            Bmp(WidgetDraw.band(context, dot + 6f, bandBottom - bandTop, s.content), context)
        }
        Column {
            Row(Modifier.height(44.dp)) {
                Column(Modifier.width(name.dp)) {
                    if (!look.header) return@Column
                    Bmp(WidgetDraw.text(context, title, 19f, s.content, 800, name - 4f), context)
                    val line = WidgetText.format(context, "week_done", "3 of 4", "{done}" to "3", "{total}" to "4") + "  ·  75%"
                    Bmp(WidgetDraw.text(context, line, 11.5f, s.content.copy(alpha = 0.6f), 600, name - 4f), context)
                }
                Column {
                    Row {
                        letters.indices.forEach { i ->
                            Box(Modifier.width(cell.dp), contentAlignment = Alignment.Center) {
                                Bmp(WidgetDraw.bar(context, 5f, 16f, if (i == 0) 1f else if (i == today) 0.5f else 0f, s.content), context)
                            }
                        }
                    }
                    Spacer(Modifier.height(5.dp))
                    Row {
                        letters.forEachIndexed { i, letter ->
                            Box(Modifier.width(cell.dp).height(22.dp), contentAlignment = Alignment.Center) {
                                if (i == today) {
                                    Bmp(WidgetDraw.pill(context, dot, letter, s.content), context)
                                } else {
                                    Bmp(WidgetDraw.text(context, letter, 10.5f, s.content.copy(alpha = 0.5f), 700), context)
                                }
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(6.dp))
            shown.forEach { (row, habit) ->
                Row(
                    Modifier.fillMaxWidth().height(rowH.dp).clip(RoundedCornerShape(15.dp))
                        .background(s.content.copy(alpha = if (look.cards) 0.07f else 0f)),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Spacer(Modifier.width(9.dp))
                    val room = name - 13f - if (look.icons) 28f else 0f
                    if (look.icons) {
                        SampleIcon(habit, 20f)
                        Spacer(Modifier.width(8.dp))
                    }
                    if (look.compact) Row(Modifier.width(room.dp), verticalAlignment = Alignment.CenterVertically) {
                        Bmp(WidgetDraw.text(context, habit.name, 11.5f, s.content, 650, room * 0.6f), context)
                        if (look.details) {
                            Spacer(Modifier.width(4.dp))
                            Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(9.dp))
                            Spacer(Modifier.width(3.dp))
                            Bmp(WidgetDraw.text(context, habit.streak.toString(), 10f, s.content.copy(alpha = 0.6f), 650), context)
                        }
                    } else Column(Modifier.width(room.dp)) {
                        Bmp(WidgetDraw.text(context, habit.name, 12.5f, s.content, 650, room - 4f), context)
                        if (look.details) Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(10.dp))
                            Spacer(Modifier.width(3.dp))
                            Bmp(WidgetDraw.text(context, habit.streak.toString(), 10f, s.content.copy(alpha = 0.6f), 650), context)
                        }
                    }
                    Spacer(Modifier.width(4.dp))
                    (0 until span).forEach { i ->
                        val mark = when {
                            i > today -> WeekMark.EMPTY
                            i == today && row == 1 -> WeekMark.PART
                            else -> WeekMark.DONE
                        }
                        Box(Modifier.width(cell.dp).height(rowH.dp), contentAlignment = Alignment.Center) {
                            Bmp(WidgetDraw.dot(context, dot, habit.color, mark, habit.fill, s.content, look.round), context)
                        }
                    }
                }
                Spacer(Modifier.height(gap.dp))
            }
        }
    }
}
