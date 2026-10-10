package com.streak.app

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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp

private data class SampleHabit(val name: String, val color: Color, val streak: Int, val button: ButtonKind, val fill: Float)

private val SAMPLE = listOf(
    SampleHabit("Read", Color(0xFF7C3AED), 38, ButtonKind.DONE, 1f),
    SampleHabit("Water", Color(0xFF38B6FF), 9, ButtonKind.AMOUNT, 0.62f),
)

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
    BoxWithConstraints(Modifier.fillMaxSize().padding(14.dp)) {
        val inner = maxWidth.value
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
            SAMPLE.forEach { habit ->
                Row(
                    Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(16.dp))
                        .background(s.content.copy(alpha = if (look.cards) 0.07f else 0f)).padding(horizontal = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Bmp(WidgetDraw.text(context, habit.name, 13.5f, s.content, 650, inner - 70f), context)
                        if (look.details) Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(painterResource(R.drawable.widget_flame_3d), null, Modifier.size(10.dp))
                            Spacer(Modifier.width(3.dp))
                            Bmp(WidgetDraw.text(context, habit.streak.toString(), 10.5f, s.content.copy(alpha = 0.6f), 650), context)
                        }
                    }
                    Bmp(WidgetDraw.button(context, 28f, habit.color, habit.button, habit.fill, s.content), context)
                }
                Spacer(Modifier.height(5.dp))
            }
        }
    }
}

@Composable
fun TodosSample(s: WidgetStyle, art: Boolean) {
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
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                listOf("Stretch" to false, "Call mom" to true).forEach { (title, done) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.width(3.dp).height(16.dp).clip(RoundedCornerShape(2.dp))
                                .background(if (done) ink.copy(alpha = 0.15f) else ink.copy(alpha = 0.85f)),
                        )
                        Spacer(Modifier.width(9.dp))
                        Box(Modifier.weight(1f)) {
                            Bmp(WidgetDraw.text(context, title, 13.5f, if (done) muted else ink, 650, strike = done), context)
                        }
                        Bmp(WidgetDraw.roundCheck(context, 22f, ink, done), context)
                    }
                }
            }
        }
    }
}

@Composable
fun WeekSample(s: WidgetStyle, span: Int = 7, look: WidgetLook = WidgetLook()) {
    val context = LocalContext.current
    val week = listOf("M", "T", "W", "T", "F", "S", "S")
    val letters = List(span) { week[it % 7] }
    val today = if (span > 7) span - 1 else 1
    BoxWithConstraints(Modifier.fillMaxSize().padding(14.dp)) {
        val inner = maxWidth.value
        val name = inner * 0.40f
        val cell = (inner - name - 8f) / span
        val dot = minOf(22f, cell - 4f)
        val title = if (span > 7) {
            WidgetText.format(context, "last_days", "Last $span days", "{count}" to span.toString())
        } else {
            sample(context, "this_week", "This week")
        }
        val bandTop = 16f + 5f + (22f - dot) / 2f - 3f
        val bandBottom = 44f + 6f + 45f + 40f / 2f + dot / 2f + 3f
        Box(Modifier.offset(x = (name + cell * today + (cell - dot - 6f) / 2f).dp, y = bandTop.dp)) {
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
            SAMPLE.forEachIndexed { row, habit ->
                Row(
                    Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(15.dp))
                        .background(s.content.copy(alpha = if (look.cards) 0.07f else 0f)),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Spacer(Modifier.width(9.dp))
                    Box(Modifier.width((name - 13f).dp)) {
                        Bmp(WidgetDraw.text(context, habit.name, 12.5f, s.content, 650, name - 17f), context)
                    }
                    Spacer(Modifier.width(4.dp))
                    (0 until span).forEach { i ->
                        val mark = when {
                            i > today -> WeekMark.EMPTY
                            i == today && row == 1 -> WeekMark.PART
                            else -> WeekMark.DONE
                        }
                        Box(Modifier.width(cell.dp).height(40.dp), contentAlignment = Alignment.Center) {
                            Bmp(WidgetDraw.dot(context, dot, habit.color, mark, habit.fill, s.content), context)
                        }
                    }
                }
                Spacer(Modifier.height(5.dp))
            }
        }
    }
}
