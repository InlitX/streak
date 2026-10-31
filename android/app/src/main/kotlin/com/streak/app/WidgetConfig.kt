package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import java.io.File

data class WidgetLook(
    val header: Boolean = true,
    val icons: Boolean = true,
    val cards: Boolean = true,
    val details: Boolean = true,
    val round: Boolean = false,
    val flower: Boolean = false,
    val tick: Boolean = true,
    val hideDone: Boolean = false,
    val hideTracking: Boolean = false,
    val todayOnly: Boolean = false,
    val compact: Boolean = false,
    val band: Boolean = true,
    val today: Boolean = false,
)

object WidgetConfig {
    private const val PREFS = "StreakWidgetConfig"
    val KINDS = listOf("habit", "today", "stats", "heatmap", "todos", "focus")
    private val templates = HashMap<Int, Int>()
    const val DEFAULT_BG = 0x101014
    const val DEFAULT_BG_LIGHT = 0xF5F5F7

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun bg(context: Context, id: Int): Int =
        prefs(context).getInt("bg_${source(context, id)}", DEFAULT_BG)

    fun bgLight(context: Context, id: Int): Int =
        prefs(context).getInt("bgLight_${source(context, id)}", DEFAULT_BG_LIGHT)

    fun followSystem(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("followSystem_${source(context, id)}", false)

    fun isNight(context: Context): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    fun bgFor(context: Context, id: Int): Int =
        if (followSystem(context, id) && !isNight(context)) bgLight(context, id)
        else bg(context, id)

    fun opacity(context: Context, id: Int): Int =
        prefs(context).getInt("opacity_${source(context, id)}", 100).coerceIn(0, 100)

    fun border(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("border_${source(context, id)}", false)

    fun borderWidth(context: Context, id: Int): Int =
        prefs(context).getInt("borderW_${source(context, id)}", 2).coerceIn(1, 8)

    fun bgMode(context: Context, id: Int): Int =
        prefs(context).getInt("bgMode_${source(context, id)}", 0)

    fun image(context: Context, id: Int): String? =
        prefs(context).getString("image_${source(context, id)}", null)

    fun art(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("art_${source(context, id)}", true)

    fun setArt(context: Context, id: Int, value: Boolean) {
        prefs(context).edit().putBoolean("art_$id", value).commit()
    }

    fun todosAll(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("todosAll_${source(context, id)}", false)

    fun setTodosAll(context: Context, id: Int, value: Boolean) {
        prefs(context).edit().putBoolean("todosAll_$id", value).commit()
    }

    fun span(context: Context, id: Int): Int =
        prefs(context).getInt("span_${source(context, id)}", 7).coerceIn(7, 9)

    fun setSpan(context: Context, id: Int, value: Int) {
        prefs(context).edit().putInt("span_$id", value).commit()
    }

    fun look(context: Context, id: Int, round: Boolean): WidgetLook {
        val p = prefs(context)
        val k = source(context, id)
        return WidgetLook(
            header = p.getBoolean("header_$k", true),
            icons = p.getBoolean("icons_$k", true),
            cards = p.getBoolean("cards_$k", true),
            details = p.getBoolean("details_$k", true),
            round = p.getBoolean("roundButtons_$k", round),
            flower = p.getBoolean("flowerButtons_$k", false),
            tick = p.getBoolean("tick_$k", true),
            hideDone = p.getBoolean("hideDone_$k", false),
            hideTracking = p.getBoolean("hideTracking_$k", false),
            todayOnly = p.getBoolean("todayOnly_$k", false),
            compact = p.getBoolean("compact_$k", false),
            band = p.getBoolean("band_$k", true),
            today = p.getBoolean("statsToday_$k", false),
        )
    }

    fun setLook(context: Context, id: Int, look: WidgetLook) {
        prefs(context).edit()
            .putBoolean("header_$id", look.header)
            .putBoolean("icons_$id", look.icons)
            .putBoolean("cards_$id", look.cards)
            .putBoolean("details_$id", look.details)
            .putBoolean("roundButtons_$id", look.round)
            .putBoolean("flowerButtons_$id", look.flower)
            .putBoolean("tick_$id", look.tick)
            .putBoolean("hideDone_$id", look.hideDone)
            .putBoolean("hideTracking_$id", look.hideTracking)
            .putBoolean("todayOnly_$id", look.todayOnly)
            .putBoolean("compact_$id", look.compact)
            .putBoolean("band_$id", look.band)
            .putBoolean("statsToday_$id", look.today)
            .commit()
    }

    fun habits(context: Context, id: Int): Set<String> =
        prefs(context).getStringSet("habits_${source(context, id)}", null)?.toSet() ?: emptySet()

    fun setHabits(context: Context, id: Int, value: Set<String>) {
        prefs(context).edit().putStringSet("habits_$id", value.toSet()).commit()
    }

    fun exists(context: Context, id: Int): Boolean =
        prefs(context).contains("bg_$id")

    fun template(kind: String): Int = -10 - KINDS.indexOf(kind).coerceAtLeast(0)

    fun kindOf(className: String): String = when {
        className.contains("Todos") -> "todos"
        className.contains("Focus") -> "focus"
        className.contains("Today") -> "today"
        className.contains("Stats") -> "stats"
        className.contains("Heatmap") -> "heatmap"
        else -> "habit"
    }

    fun source(context: Context, id: Int): Int {
        if (id < 0 || exists(context, id)) return id
        val base = templates.getOrPut(id) {
            val provider = AppWidgetManager.getInstance(context).getAppWidgetInfo(id)?.provider
                ?: return id
            template(kindOf(provider.className))
        }
        return if (exists(context, base)) base else id
    }

    fun set(
        context: Context,
        id: Int,
        bg: Int,
        opacity: Int,
        border: Boolean,
        borderWidth: Int,
        bgMode: Int,
        image: String?,
        followSystem: Boolean,
        bgLight: Int,
    ) {
        prefs(context).edit()
            .putInt("bg_$id", bg and 0x00FFFFFF)
            .putInt("bgLight_$id", bgLight and 0x00FFFFFF)
            .putBoolean("followSystem_$id", followSystem)
            .putInt("opacity_$id", opacity.coerceIn(0, 100))
            .putBoolean("border_$id", border)
            .putInt("borderW_$id", borderWidth.coerceIn(1, 8))
            .putInt("bgMode_$id", bgMode)
            .apply {
                if (image == null) remove("image_$id") else putString("image_$id", image)
            }
            .commit()
    }

    fun clear(context: Context, id: Int) {
        prefs(context).edit()
            .remove("bg_$id")
            .remove("bgLight_$id")
            .remove("followSystem_$id")
            .remove("opacity_$id")
            .remove("border_$id")
            .remove("borderW_$id")
            .remove("bgMode_$id")
            .remove("image_$id")
            .remove("todosAll_$id")
            .remove("art_$id")
            .remove("span_$id")
            .remove("round_$id")
            .remove("habits_$id")
            .remove("header_$id")
            .remove("icons_$id")
            .remove("cards_$id")
            .remove("details_$id")
            .remove("roundButtons_$id")
            .remove("flowerButtons_$id")
            .remove("tick_$id")
            .remove("hideDone_$id")
            .remove("hideTracking_$id")
            .remove("todayOnly_$id")
            .remove("compact_$id")
            .remove("band_$id")
            .remove("statsToday_$id")
            .apply()
    }

    fun forget(context: Context, id: Int) {
        deleteImage(context, prefs(context).getString("image_$id", null))
        clear(context, id)
    }

    fun deleteImage(context: Context, path: String?) {
        if (path == null) return
        try {
            val f = File(path)
            if (f.exists() && f.parentFile == File(context.filesDir, "widget_images")) f.delete()
        } catch (_: Exception) {
        }
    }
}
