package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import java.util.Locale
import org.json.JSONObject

private val PRIORITY_COLORS = listOf(
    null,
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
)

private val DONE = Color(0xFF22C55E)

private val OVERDUE = Color(0xFFEF4444)

class TodosWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            currentState<HomeWidgetGlanceState>()
            Content(
                context,
                WidgetStyle.loadFor(context, appWidgetId),
                WidgetConfig.todosAll(context, appWidgetId),
            )
        }
    }

    @Composable
    private fun Content(context: Context, style: WidgetStyle, all: Boolean) {
        val todos = TodosPayload.due(context, all)
        val open = todos.count { !it.optBoolean("done", false) }
        WidgetSurface(style) {
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .clickable(actionStartActivity<MainActivity>())
            ) {
                Text(
                    text = WidgetText.format(
                        context,
                        "todos_open",
                        "To-do  $open",
                        "{count}" to open.toString(),
                    ),
                    style = TextStyle(
                        color = ColorProvider(style.content),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                Spacer(modifier = GlanceModifier.height(10.dp))

                if (todos.isEmpty()) {
                    Text(
                        text = WidgetText.get(
                            context,
                            if (TodosPayload.raw(context) == null) "open_to_sync" else "todos_empty",
                            "Nothing left for today",
                        ),
                        style = TextStyle(
                            color = ColorProvider(style.muted),
                            fontSize = 13.sp,
                        ),
                    )
                } else {
                    LazyColumn(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                        items(todos.size) { i -> TodoRow(context, style, todos[i]) }
                    }
                }
            }
        }
    }

    @Composable
    private fun TodoRow(context: Context, style: WidgetStyle, todo: JSONObject) {
        val id = todo.optString("id")
        val title = todo.optString("title")
        val day = todo.optLong("day", -1L)
        val done = todo.optBoolean("done", false)
        val overdue = !done && day >= 0L && day < TodosPayload.todayEpochDay()
        val priority = PRIORITY_COLORS.getOrNull(todo.optInt("priority", 0))

        Row(
            modifier = GlanceModifier.fillMaxWidth().padding(vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val box = GlanceModifier
                .size(24.dp)
                .cornerRadius(7.dp)
                .background(ColorProvider(if (done) DONE else style.cell))
            Box(
                modifier = box.clickable(
                    onClick = actionSendBroadcast(
                        WidgetActionReceiver.todoIntent(context, id)
                    )
                ),
                contentAlignment = Alignment.Center,
            ) {
                if (done) {
                    Text(
                        text = "✓",
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                }
            }
            Spacer(modifier = GlanceModifier.width(10.dp))
            if (priority != null && !done) {
                Box(
                    modifier = GlanceModifier
                        .size(7.dp)
                        .cornerRadius(4.dp)
                        .background(ColorProvider(priority)),
                ) {}
                Spacer(modifier = GlanceModifier.width(7.dp))
            }
            Text(
                text = title,
                style = TextStyle(
                    color = ColorProvider(if (done) style.muted else style.content),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    textDecoration = if (done) TextDecoration.LineThrough else null,
                ),
                maxLines = 1,
                modifier = GlanceModifier
                    .defaultWeight()
                    .clickable(actionStartActivity<MainActivity>()),
            )
            val label = if (done) "" else trailing(context, todo, overdue)
            if (label.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.width(8.dp))
                Text(
                    text = label,
                    style = TextStyle(
                        color = ColorProvider(if (overdue) OVERDUE else style.muted),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                    ),
                    maxLines = 1,
                )
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
