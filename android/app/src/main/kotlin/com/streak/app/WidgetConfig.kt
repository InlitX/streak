package com.streak.app

import android.content.Context
import android.content.res.Configuration
import java.io.File

data class WidgetLook(
    val header: Boolean = true,
    val icons: Boolean = true,
    val cards: Boolean = true,
    val details: Boolean = true,
)

object WidgetConfig {
    private const val PREFS = "StreakWidgetConfig"
    const val DEFAULT_BG = 0x101014
    const val DEFAULT_BG_LIGHT = 0xF5F5F7

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun bg(context: Context, id: Int): Int =
        prefs(context).getInt("bg_$id", DEFAULT_BG)

    fun bgLight(context: Context, id: Int): Int =
        prefs(context).getInt("bgLight_$id", DEFAULT_BG_LIGHT)

    fun followSystem(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("followSystem_$id", false)

    fun isNight(context: Context): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    fun bgFor(context: Context, id: Int): Int =
        if (followSystem(context, id) && !isNight(context)) bgLight(context, id)
        else bg(context, id)

    fun opacity(context: Context, id: Int): Int =
        prefs(context).getInt("opacity_$id", 100).coerceIn(0, 100)

    fun border(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("border_$id", false)

    fun borderWidth(context: Context, id: Int): Int =
        prefs(context).getInt("borderW_$id", 2).coerceIn(1, 8)

    fun bgMode(context: Context, id: Int): Int =
        prefs(context).getInt("bgMode_$id", 0)

    fun image(context: Context, id: Int): String? =
        prefs(context).getString("image_$id", null)

    fun art(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("art_$id", true)

    fun setArt(context: Context, id: Int, value: Boolean) {
        prefs(context).edit().putBoolean("art_$id", value).commit()
    }

    fun todosAll(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("todosAll_$id", false)

    fun setTodosAll(context: Context, id: Int, value: Boolean) {
        prefs(context).edit().putBoolean("todosAll_$id", value).commit()
    }

    fun span(context: Context, id: Int): Int =
        prefs(context).getInt("span_$id", 7).coerceIn(7, 9)

    fun setSpan(context: Context, id: Int, value: Int) {
        prefs(context).edit().putInt("span_$id", value).commit()
    }

    fun look(context: Context, id: Int): WidgetLook {
        val p = prefs(context)
        return WidgetLook(
            header = p.getBoolean("header_$id", true),
            icons = p.getBoolean("icons_$id", true),
            cards = p.getBoolean("cards_$id", true),
            details = p.getBoolean("details_$id", true),
        )
    }

    fun setLook(context: Context, id: Int, look: WidgetLook) {
        prefs(context).edit()
            .putBoolean("header_$id", look.header)
            .putBoolean("icons_$id", look.icons)
            .putBoolean("cards_$id", look.cards)
            .putBoolean("details_$id", look.details)
            .commit()
    }

    fun habits(context: Context, id: Int): Set<String> =
        prefs(context).getStringSet("habits_$id", null)?.toSet() ?: emptySet()

    fun setHabits(context: Context, id: Int, value: Set<String>) {
        prefs(context).edit().putStringSet("habits_$id", value.toSet()).commit()
    }

    fun exists(context: Context, id: Int): Boolean =
        prefs(context).contains("bg_$id")

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
            .apply()
    }

    fun forget(context: Context, id: Int) {
        deleteImage(context, image(context, id))
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
