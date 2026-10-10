package com.streak.app

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
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
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.unit.ColorProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

private val PRIORITY_COLORS = listOf(
    null,
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
)

private val OVERDUE = Color(0xFFFF5448)

private data class CardInk(val surface: Color, val ink: Color, val muted: Color)

private val LIGHT_CARD = CardInk(Color(0xF7FFFFFF), Color(0xFF16161C), Color(0x8C16161C))

private val DARK_CARD = CardInk(Color(0xF21C1C22), Color(0xFFF5F5F7), Color(0x99F5F5F7))

private const val PAD_DP = 10f

class TodosWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            currentState(GlanceWidgets.REVISION)
            Content(
                context,
                WidgetStyle.loadFor(context, appWidgetId),
                WidgetConfig.todosAll(context, appWidgetId),
                WidgetConfig.art(context, appWidgetId),
            )
        }
    }

    @Composable
    private fun Content(context: Context, style: WidgetStyle, all: Boolean, art: Boolean) {
        val todos = TodosPayload.due(context, all)
        val done = todos.count { it.optBoolean("done", false) }
        val size = LocalSize.current
        val wide = size.width.value >= 250f
        val night = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val card = if (night) DARK_CARD else LIGHT_CARD
        val density = WidgetDraw.density(context)
        WidgetSurface(style, radius = 22.dp) {
            if (wide) {
                val left = size.width.value * 0.36f
                Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.BottomStart) {
                    if (art) {
                        Image(
                            provider = ImageProvider(stickerFor(style)),
                            contentDescription = null,
                            modifier = GlanceModifier.size(size.height),
                        )
                    }
                    Row(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .padding(PAD_DP.dp)
                            .clickable(openPageAction(context, "todos")),
                    ) {
                        Column(
                            modifier = GlanceModifier
                                .width((left - PAD_DP).dp)
                                .fillMaxHeight()
                                .padding(start = 6.dp, top = 2.dp, end = 6.dp),
                        ) {
                            DateBlock(context, style, density, 26f, left - PAD_DP - 12f)
                            if (todos.isNotEmpty()) {
                                Spacer(GlanceModifier.height(4.dp))
                                Tally(context, style, density, done, todos.size, 12f)
                            }
                        }
                        Card(
                            context, card, density, todos, size.width.value - left - PAD_DP,
                            GlanceModifier.defaultWeight().fillMaxHeight(),
                        )
                    }
                }
            } else {
                Column(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .padding(PAD_DP.dp)
                        .clickable(openPageAction(context, "todos")),
                ) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth().padding(start = 4.dp, end = 4.dp, bottom = 8.dp),
                        verticalAlignment = Alignment.Bottom,
                    ) {
                        Column(modifier = GlanceModifier.defaultWeight()) {
                            DateBlock(context, style, density, 21f, size.width.value - PAD_DP * 2 - 52f)
                        }
                        if (todos.isNotEmpty()) {
                            Drawn(WidgetDraw.text(context, "$done/${todos.size}", 15f, style.content, 800), density)
                        }
                    }
                    Card(
                        context, card, density, todos, size.width.value - PAD_DP * 2,
                        GlanceModifier.fillMaxWidth().defaultWeight(),
                    )
                }
            }
        }
    }

    private fun stickerFor(style: WidgetStyle): Int =
        if (style.content.luminance() < 0.5f) R.drawable.widget_todo_sticker_light
        else R.drawable.widget_todo_sticker

    @Composable
    private fun DateBlock(context: Context, style: WidgetStyle, density: Float, size: Float, room: Float) {
        val root = WidgetPayload.raw(context)?.takeIf { !WidgetPayload.isStale(context) }
        val now = Date()
        val weekday = root?.optString("weekdayLabel").orEmpty()
            .ifEmpty { SimpleDateFormat("EEEE", Locale.getDefault()).format(now) }
        val date = root?.optString("dateLabel").orEmpty()
            .ifEmpty { SimpleDateFormat("MMM d", Locale.getDefault()).format(now) }
        Drawn(WidgetDraw.text(context, weekday, 12f, style.content.copy(alpha = 0.62f), 650, room), density, weekday)
        Drawn(WidgetDraw.text(context, date, size, style.content, 800, room), density, date)
    }

    @Composable
    private fun Tally(context: Context, style: WidgetStyle, density: Float, done: Int, total: Int, size: Float) {
        val line = WidgetText.format(
            context, "today_done", "$done of $total done",
            "{done}" to done.toString(), "{total}" to total.toString(),
        )
        Drawn(WidgetDraw.text(context, line, size, style.content.copy(alpha = 0.8f), 700), density, line)
    }

    @Composable
    private fun Card(
        context: Context,
        card: CardInk,
        density: Float,
        todos: List<JSONObject>,
        width: Float,
        modifier: GlanceModifier,
    ) {
        Column(
            modifier = modifier
                .cornerRadius(18.dp)
                .background(ColorProvider(card.surface))
                .padding(start = 12.dp, top = 9.dp, bottom = 9.dp),
        ) {
            val edge = GlanceModifier.fillMaxWidth().padding(end = 12.dp)
            val title = WidgetText.title(context, "todos_open", "To-do")
            Drawn(WidgetDraw.text(context, title, 11.5f, card.muted, 700, width - 24f), density, title)
            Spacer(GlanceModifier.height(6.dp))
            if (todos.isEmpty()) {
                val empty = WidgetText.get(
                    context,
                    if (TodosPayload.raw(context) == null) "open_to_sync" else "todos_empty",
                    "Nothing left for today",
                )
                Drawn(WidgetDraw.text(context, empty, 13f, card.muted, 600, width - 24f), density, empty)
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    items(todos.size) { i -> Box(edge) { TodoRow(context, card, density, todos[i], width - 24f) } }
                }
            }
        }
    }

    @Composable
    private fun TodoRow(context: Context, card: CardInk, density: Float, todo: JSONObject, width: Float) {
        val id = todo.optString("id")
        val title = todo.optString("title")
        val day = todo.optLong("day", -1L)
        val done = todo.optBoolean("done", false)
        val overdue = !done && day >= 0L && day < TodosPayload.todayEpochDay()
        val priority = PRIORITY_COLORS.getOrNull(todo.optInt("priority", 0))
        val label = if (done) "" else trailing(context, todo, overdue)
        val room = width - 12f - 8f - 26f

        Row(
            modifier = GlanceModifier.fillMaxWidth().padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = GlanceModifier
                    .width(3.dp)
                    .height(if (label.isEmpty()) 16.dp else 28.dp)
                    .cornerRadius(2.dp)
                    .background(
                        ColorProvider(
                            when {
                                done -> card.ink.copy(alpha = 0.15f)
                                priority != null -> priority
                                else -> card.ink.copy(alpha = 0.85f)
                            },
                        ),
                    ),
            ) {}
            Spacer(GlanceModifier.width(9.dp))
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .clickable(openPageAction(context, "todos")),
            ) {
                Drawn(
                    WidgetDraw.text(context, title, 13.5f, if (done) card.muted else card.ink, 650, room, strike = done),
                    density,
                    title,
                )
                if (label.isNotEmpty()) {
                    Drawn(
                        WidgetDraw.text(context, label, 11f, if (overdue) OVERDUE else card.muted, 650, room),
                        density,
                        label,
                    )
                }
            }
            Spacer(GlanceModifier.width(8.dp))
            Box(
                modifier = GlanceModifier
                    .size(26.dp)
                    .clickable(actionSendBroadcast(WidgetActionReceiver.todoIntent(context, id))),
                contentAlignment = Alignment.Center,
            ) {
                Drawn(WidgetDraw.roundCheck(context, 22f, card.ink, done), density)
            }
        }
    }

    private fun trailing(context: Context, todo: JSONObject, overdue: Boolean): String {
        if (!todo.has("minutes")) {
            return if (overdue) "!" else ""
        }
        val minutes = todo.optInt("minutes", 0)
        val hour = minutes / 60
        val rest = minutes % 60
        if (android.text.format.DateFormat.is24HourFormat(context)) {
            return String.format(Locale.US, "%02d:%02d", hour, rest)
        }
        val suffix = if (hour < 12) "AM" else "PM"
        val shown = when {
            hour % 12 == 0 -> 12
            else -> hour % 12
        }
        return String.format(Locale.US, "%d:%02d %s", shown, rest, suffix)
    }
}
