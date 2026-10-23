package com.streak.app

import android.content.Context
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
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import org.json.JSONObject
import kotlin.math.min

class StatsWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            currentState(GlanceWidgets.REVISION)
            Content(context, WidgetStyle.loadFor(context, appWidgetId), appWidgetId)
        }
    }

    @Composable
    private fun Content(context: Context, style: WidgetStyle, appWidgetId: Int) {
        val data = WidgetPayload.forWidget(context, appWidgetId)
        val single = WidgetPayload.single(context, appWidgetId, data)
        val streak = single?.optInt("streak") ?: longest(data)
        val art = WidgetConfig.art(context, appWidgetId)

        val size = LocalSize.current
        val side = min(maxOf(size.width.value, size.height.value), size.width.value * 1.25f)
        val pad = (side * 0.11f).coerceIn(12f, 20f)
        val room = size.width.value - pad * 2
        val density = WidgetDraw.density(context)
        val label = (side * 0.1f).coerceIn(13f, 18f)

        WidgetSurface(style) {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .clickable(openPageAction(context, "stats")),
                contentAlignment = Alignment.BottomEnd,
            ) {
                if (art) {
                    Image(
                        provider = ImageProvider(flameFor(style)),
                        contentDescription = null,
                        modifier = GlanceModifier.size(side.dp),
                    )
                }
                Column(modifier = GlanceModifier.fillMaxSize().padding(pad.dp)) {
                    val number = WidgetText.compact(streak)
                    Drawn(
                        WidgetDraw.text(context, number, (side * 0.3f).coerceIn(30f, 60f), style.content, 800, room),
                        density,
                        number,
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (!art) {
                            Flame(label.dp)
                            Spacer(GlanceModifier.width(4.dp))
                        }
                        val days = WidgetText.get(context, "streak_days", "Streak days")
                        Drawn(
                            WidgetDraw.text(context, days, label, style.content, 800, room - if (art) 0f else label + 4f),
                            density,
                            days,
                        )
                    }
                    if (single != null) {
                        val name = single.optString("name")
                        Drawn(
                            WidgetDraw.haloText(
                                context, name, (side * 0.08f).coerceIn(11f, 14f), style.muted,
                                if (style.dark) Color.Black else Color.White, 600, room,
                            ),
                            density,
                            name,
                        )
                    }
                }
            }
        }
    }

    private fun flameFor(style: WidgetStyle): Int =
        if (style.content.luminance() < 0.5f) R.drawable.widget_streak_flame_light
        else R.drawable.widget_streak_flame

    private fun longest(data: JSONObject?): Int {
        val habits = data?.optJSONArray("habits") ?: return 0
        var best = 0
        for (i in 0 until habits.length()) {
            best = maxOf(best, habits.optJSONObject(i)?.optInt("streak", 0) ?: 0)
        }
        return best
    }
}
