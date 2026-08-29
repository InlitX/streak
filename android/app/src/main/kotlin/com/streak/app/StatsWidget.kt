package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.GlanceAppWidgetManager
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
import androidx.glance.unit.ColorProvider
import org.json.JSONObject

class StatsWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            currentState<HomeWidgetGlanceState>()
            Content(context, WidgetStyle.loadFor(context, appWidgetId))
        }
    }

    @Composable
    private fun Content(context: Context, style: WidgetStyle) {
        val summary = loadData(context)?.optJSONObject("summary")
        val done = summary?.optInt("doneToday") ?: 0
        val total = summary?.optInt("total") ?: 0
        val best = summary?.optInt("bestStreak") ?: 0
        val week = summary?.optInt("weekDone") ?: 0

        val height = LocalSize.current.height.value
        val tiny = height < 125f
        val roomy = height >= 175f
        val pad = if (tiny) 11 else if (roomy) 16 else 13

        WidgetSurface(style) {
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(pad.dp)
                    .clickable(openPageAction(context, "stats")),
                verticalAlignment = Alignment.Top,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "🔥",
                        style = TextStyle(fontSize = if (tiny) 10.sp else 12.sp),
                    )
                    Spacer(modifier = GlanceModifier.width(5.dp))
                    Text(
                        text = spaced("Streak"),
                        style = TextStyle(
                            color = ColorProvider(style.muted),
                            fontSize = if (tiny) 9.sp else 10.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                }
                Spacer(modifier = GlanceModifier.height(if (tiny) 4.dp else 8.dp))
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = WidgetText.compact(done),
                        style = TextStyle(
                            color = ColorProvider(style.content),
                            fontSize = if (tiny) 26.sp else if (roomy) 40.sp else 32.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                    Spacer(modifier = GlanceModifier.width(5.dp))
                    Text(
                        text = "/ ${WidgetText.compact(total)}",
                        style = TextStyle(
                            color = ColorProvider(style.muted),
                            fontSize = if (tiny) 13.sp else 16.sp,
                            fontWeight = FontWeight.Medium,
                        ),
                    )
                }
                if (!tiny) {
                    Text(
                        text = WidgetText.get(context, "done_today", "done today"),
                        style = TextStyle(
                            color = ColorProvider(style.muted),
                            fontSize = 11.sp,
                        ),
                    )
                }
                Spacer(modifier = GlanceModifier.defaultWeight())
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    Tile(
                        style = style,
                        value = WidgetText.compact(week),
                        label = WidgetText.get(context, "label_week", "Week"),
                        tiny = tiny,
                        modifier = GlanceModifier.defaultWeight(),
                    )
                    Spacer(modifier = GlanceModifier.width(7.dp))
                    Tile(
                        style = style,
                        value = "🔥${WidgetText.compact(best)}",
                        label = WidgetText.get(context, "label_best", "Best"),
                        tiny = tiny,
                        modifier = GlanceModifier.defaultWeight(),
                    )
                }
            }
        }
    }

    @Composable
    private fun Tile(
        style: WidgetStyle,
        value: String,
        label: String,
        tiny: Boolean,
        modifier: GlanceModifier,
    ) {
        Column(
            modifier = modifier
                .background(ColorProvider(style.cell))
                .cornerRadius(12.dp)
                .padding(horizontal = 9.dp, vertical = if (tiny) 5.dp else 7.dp),
        ) {
            Text(
                text = value,
                style = TextStyle(
                    color = ColorProvider(style.content),
                    fontSize = if (tiny) 13.sp else 16.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Text(
                text = label.uppercase(),
                style = TextStyle(
                    color = ColorProvider(style.muted),
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Medium,
                ),
            )
        }
    }

    private fun spaced(value: String) = value.uppercase().toCharArray().joinToString(" ")

    private fun loadData(context: Context): JSONObject? = WidgetPayload.aligned(context)
}
