package com.streak.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
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
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import org.json.JSONObject
import kotlin.math.min

class FocusWidget : GlanceAppWidget() {

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
        val chosen = WidgetConfig.habits(context, appWidgetId)
        val picks = if (single != null) emptyList() else picks(data, chosen)
        val spot = WidgetScroll.spot(context, appWidgetId, picks.size + 1)
        val pick = single ?: picks.getOrNull(spot - 1)
        val totals = totals(data, pick?.optString("id")?.let { setOf(it) } ?: chosen)
        val art = WidgetConfig.art(context, appWidgetId)

        val size = LocalSize.current
        val side = min(maxOf(size.width.value, size.height.value), size.width.value * 1.25f)
        val pad = (side * 0.11f).coerceIn(12f, 20f)
        val room = size.width.value - pad * 2
        val density = WidgetDraw.density(context)
        val label = (side * 0.1f).coerceIn(13f, 18f)
        val button = (side * 0.2f).coerceIn(30f, 42f)
        val start = pick?.optString("id")?.takeIf { it.isNotEmpty() }?.let { "focusStart:$it" } ?: "focusStart"

        WidgetSurface(style) {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .clickable(openPageAction(context, "focusPage")),
                contentAlignment = Alignment.BottomEnd,
            ) {
                if (art) {
                    Image(
                        provider = ImageProvider(targetFor(style)),
                        contentDescription = null,
                        modifier = GlanceModifier.size(side.dp),
                    )
                }
                Column(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .padding(start = pad.dp, end = pad.dp, top = (pad * 1.5f).dp, bottom = pad.dp),
                ) {
                    val today = duration(totals[0])
                    val big = WidgetDraw.fit(context, today, (side * 0.22f).coerceIn(24f, 46f), 16f, 800, room - button - 6f)
                    Drawn(WidgetDraw.text(context, today, big, style.content, 800, room - button - 6f), density, today)
                    val caption = WidgetText.get(context, "focus_today", "Focus today")
                    Drawn(WidgetDraw.text(context, caption, label, style.content, 800, room), density, caption)
                    Spacer(GlanceModifier.height(6.dp))
                    val small = label * 0.85f
                    val halo = if (style.dark) Color.Black else Color.White
                    val week = "${WidgetText.get(context, "label_week", "Week")}  ${duration(totals[1])}"
                    Drawn(WidgetDraw.haloText(context, week, small, style.muted, halo, 650, room), density, week)
                    val month = "${WidgetText.get(context, "label_month", "Month")}  ${duration(totals[2])}"
                    Drawn(WidgetDraw.haloText(context, month, small, style.muted, halo, 650, room), density, month)
                    if (picks.isNotEmpty()) {
                        Spacer(GlanceModifier.height(2.dp))
                        val name = pick?.optString("name") ?: WidgetText.get(context, "cfg_all_habits", "All habits")
                        val arrow = (side * 0.15f).coerceIn(22f, 28f)
                        val ink = style.content.toArgb()
                        val under = halo.copy(alpha = 0.85f).toArgb()
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(modifier = GlanceModifier.size(arrow.dp).clickable(WidgetScroll.turnAction(context, appWidgetId, -1, picks.size + 1))) {
                                Drawn(WidgetScroll.sideArrow(context, ink, under, true, arrow), density, "previous")
                            }
                            Box(
                                modifier = GlanceModifier.width((room - arrow * 2).dp).padding(horizontal = 4.dp),
                                contentAlignment = Alignment.CenterStart,
                            ) {
                                Drawn(
                                    WidgetDraw.haloText(context, name, (side * 0.08f).coerceIn(11f, 14f), style.content, halo, 700, room - arrow * 2 - 8f),
                                    density,
                                    name,
                                )
                            }
                            Box(modifier = GlanceModifier.size(arrow.dp).clickable(WidgetScroll.turnAction(context, appWidgetId, 1, picks.size + 1))) {
                                Drawn(WidgetScroll.sideArrow(context, ink, under, false, arrow), density, "next")
                            }
                        }
                    } else if (single != null) {
                        val name = single.optString("name")
                        Drawn(
                            WidgetDraw.haloText(context, name, (side * 0.08f).coerceIn(11f, 14f), style.muted, halo, 600, room),
                            density,
                            name,
                        )
                    }
                }
                Box(
                    modifier = GlanceModifier.fillMaxSize().padding(pad.dp),
                    contentAlignment = Alignment.TopEnd,
                ) {
                    Image(
                        provider = ImageProvider(WidgetDraw.play(context, button, style.content)),
                        contentDescription = WidgetText.get(context, "focus_start", "Start focus"),
                        modifier = GlanceModifier.size(button.dp).clickable(openPageAction(context, start)),
                    )
                }
            }
        }
    }

    private fun targetFor(style: WidgetStyle): Int =
        if (style.content.luminance() < 0.5f) R.drawable.widget_focus_target_light
        else R.drawable.widget_focus_target

    private fun picks(data: JSONObject?, chosen: Set<String>): List<JSONObject> {
        val habits = data?.optJSONArray("habits") ?: return emptyList()
        val list = mutableListOf<JSONObject>()
        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            val id = habit.optString("id")
            if (id.isEmpty() || habit.optBoolean("tracking", false)) continue
            if (if (chosen.isEmpty()) habit.optBoolean("focusOnly", false) else id in chosen) list.add(habit)
        }
        return list
    }

    private fun totals(data: JSONObject?, chosen: Set<String>): IntArray {
        val focus = data?.optJSONObject("focus") ?: return IntArray(3)
        val keys = if (chosen.isEmpty()) listOf("") else chosen.toList()
        val sums = IntArray(3)
        for (key in keys) {
            val values = focus.optJSONArray(key) ?: continue
            for (i in 0 until 3) sums[i] += values.optInt(i)
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
