package com.streak.app

import android.content.Context
import android.content.res.Configuration
import java.io.File

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

    fun todosAll(context: Context, id: Int): Boolean =
        prefs(context).getBoolean("todosAll_$id", false)

    fun setTodosAll(context: Context, id: Int, value: Boolean) {
        prefs(context).edit().putBoolean("todosAll_$id", value).commit()
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
