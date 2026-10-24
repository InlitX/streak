package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
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
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import org.json.JSONObject

class FocusBoardWidget : GlanceAppWidget() {

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
        val totals = totals(data, WidgetConfig.habits(context, appWidgetId))
        val labels = labels(data)

        val size = LocalSize.current
        val height = size.height.value
        val pad = (height * 0.1f).coerceIn(12f, 18f)
        val left = (size.width.value - pad * 3) * 0.55f
        val right = size.width.value - pad * 3 - left
        val density = WidgetDraw.density(context)
        val label = (height * 0.085f).coerceIn(12f, 16f)
        val small = label * 0.85f
        val button = (height * 0.22f).coerceIn(30f, 40f)
        val halo = if (style.dark) Color.Black else Color.White
        val start = single?.optString("id")?.takeIf { it.isNotEmpty() }?.let { "focusStart:$it" } ?: "focusStart"

        WidgetSurface(style) {
            Row(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(pad.dp)
                    .clickable(openPageAction(context, "focusPage")),
            ) {
                Column(modifier = GlanceModifier.width(left.dp).fillMaxHeight()) {
                    val today = duration(totals[0])
                    val big = WidgetDraw.fit(context, today, (height * 0.22f).coerceIn(24f, 44f), 16f, 800, left)
                    Drawn(WidgetDraw.text(context, today, big, style.content, 800, left), density, today)
                    val caption = WidgetText.get(context, "focus_today", "Focus today")
                    Drawn(WidgetDraw.text(context, caption, label, style.content, 800, left), density, caption)
                    Spacer(GlanceModifier.defaultWeight())
                    val week = "${WidgetText.get(context, "label_week", "Week")}  ${duration(totals[1])}"
                    Drawn(WidgetDraw.haloText(context, week, small, style.muted, halo, 650, left), density, week)
                    val month = "${WidgetText.get(context, "label_month", "Month")}  ${duration(totals[2])}"
                    Drawn(WidgetDraw.haloText(context, month, small, style.muted, halo, 650, left), density, month)
                    if (single != null) {
                        val name = single.optString("name")
                        Drawn(WidgetDraw.haloText(context, name, small, style.muted, halo, 600, left), density, name)
                    }
                }
                Spacer(GlanceModifier.width(pad.dp))
                Column(modifier = GlanceModifier.width(right.dp).fillMaxHeight()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = GlanceModifier.width((right - button - 4f).dp)) {
                            val streak = WidgetText.compact(totals[3])
                            Drawn(WidgetDraw.text(context, streak, label * 1.9f, style.content, 800), density, streak)
                            val days = WidgetText.get(context, "streak_days", "Streak days")
                            Drawn(
                                WidgetDraw.haloText(context, days, small, style.muted, halo, 650, right - button - 4f),
                                density,
                                days,
                            )
                        }
                        Spacer(GlanceModifier.width(4.dp))
                        Image(
                            provider = ImageProvider(WidgetDraw.play(context, button, style.content)),
                            contentDescription = WidgetText.get(context, "focus_start", "Start focus"),
                            modifier = GlanceModifier.size(button.dp).clickable(openPageAction(context, start)),
                        )
                    }
                    Spacer(GlanceModifier.height(6.dp).defaultWeight())
                    val header = maxOf(button, (label * 1.9f + small) * 1.3f * WidgetDraw.textScale(context))
                    val chart = (height - pad * 2 - header - 10f).coerceAtLeast(24f)
                    val values = IntArray(7) { totals[4 + it] }
                    Image(
                        provider = ImageProvider(WidgetDraw.weekBars(context, right, chart, values, labels, style.content)),
                        contentDescription = null,
                        modifier = GlanceModifier.width(right.dp).height(chart.dp),
                    )
                }
            }
        }
    }

    private fun labels(data: JSONObject?): List<String> {
        val days = data?.optJSONArray("days") ?: return emptyList()
        return (0 until minOf(7, days.length())).map { days.optJSONObject(it)?.optString("label").orEmpty() }
    }

    private fun totals(data: JSONObject?, chosen: Set<String>): IntArray {
        val focus = data?.optJSONObject("focus") ?: return IntArray(11)
        val keys = if (chosen.isEmpty()) listOf("") else chosen.toList()
        val sums = IntArray(11)
        for (key in keys) {
            val values = focus.optJSONArray(key) ?: continue
            for (i in 0 until 11) {
                if (i == 3) sums[3] = maxOf(sums[3], values.optInt(3)) else sums[i] += values.optInt(i)
            }
        }
        return sums
    }

    private fun duration(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = seconds % 3600 / 60
        return when {
            hours == 0 -> "${minutes}m"
            minutes == 0 -> "${hours}h"
            else -> "${hours}h ${minutes}m"
        }
    }
}
