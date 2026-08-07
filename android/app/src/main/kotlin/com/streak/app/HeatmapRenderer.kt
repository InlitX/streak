package com.streak.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

object HeatmapRenderer {

    private const val PAD_DP = 12f
    private const val GAP_DP = 10f
    private const val TILE_MAX_DP = 42f
    private const val TILE_MIN_DP = 28f
    private const val RADIUS_DP = 20f
    private const val CLASSIC_TITLE_DP = 24f
    private const val TIGHT_WIDTH_DP = 180f

    fun update(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        try {
            manager.updateAppWidget(appWidgetId, build(context, manager, appWidgetId))
        } catch (e: Exception) {
            return
        }
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (id in targets(context, manager)) update(context, manager, id)
    }

    fun refreshContent(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (id in targets(context, manager)) {
            try {
                val partial = content(context, manager, id)
                if (partial != null) manager.partiallyUpdateAppWidget(id, partial)
                else update(context, manager, id)
            } catch (e: Exception) {
                update(context, manager, id)
            }
        }
    }

    private fun targets(context: Context, manager: AppWidgetManager): IntArray =
        manager.getAppWidgetIds(ComponentName(context, HeatmapWidgetProvider::class.java))

    private fun content(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
    ): RemoteViews? {
        val data = HabitCardData.load(
            context,
            HeatmapConfig.habitOf(context, appWidgetId),
            HeatmapConfig.colorOf(context, appWidgetId),
        ) ?: return null
        if (data.levels.isEmpty()) return null

        val style = CardStyle.loadFor(context, appWidgetId)
        val layout = HeatmapConfig.layoutOf(context, appWidgetId)
        val density = context.resources.displayMetrics.density

        val options = manager.getAppWidgetOptions(appWidgetId)
        val widthDp = sizeOf(options, AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250f)
        val heightDp = sizeOf(options, AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110f)

        val classic = layout == HeatmapConfig.LAYOUT_CLASSIC
        val tight = !classic && widthDp < TIGHT_WIDTH_DP
        val innerHeight = heightDp - PAD_DP * 2
        val views = RemoteViews(context.packageName, R.layout.widget_heatmap)

        val gridHeightDp: Float
        if (classic) {
            gridHeightDp = innerHeight - CLASSIC_TITLE_DP - GAP_DP
        } else {
            val tileDp = (innerHeight * 0.32f).coerceIn(TILE_MIN_DP, TILE_MAX_DP)
            val tilePx = (tileDp * density).toInt()
            val filled = tight && data.doneToday
            views.setImageViewBitmap(
                R.id.hm_tile,
                CardBitmaps.tile(
                    tilePx,
                    if (filled) data.color else CardBitmaps.withAlpha(data.color, 0.20f),
                    data.iconPath,
                    when {
                        !data.iconTintable -> null
                        filled -> Color.WHITE
                        tight -> data.color
                        else -> style.content
                    },
                ),
            )
            if (!tight && data.id != null) {
                views.setImageViewBitmap(
                    R.id.hm_check,
                    CardBitmaps.check(
                        tilePx,
                        if (data.doneToday) {
                            data.color
                        } else {
                            CardBitmaps.withAlpha(data.color, 0.20f)
                        },
                        if (data.doneToday) Color.WHITE else data.color,
                    ),
                )
            }
            gridHeightDp = innerHeight - tileDp - GAP_DP
        }

        views.setImageViewBitmap(
            R.id.hm_grid,
            CardBitmaps.grid(
                ((widthDp - PAD_DP * 2) * density).toInt(),
                (gridHeightDp * density).toInt(),
                data.levels,
                data.color,
                if (classic) style.cell else null,
            ),
        )
        return views
    }

    private fun build(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_heatmap)
        val style = CardStyle.loadFor(context, appWidgetId)
        val layout = HeatmapConfig.layoutOf(context, appWidgetId)
        val density = context.resources.displayMetrics.density

        val options = manager.getAppWidgetOptions(appWidgetId)
        val widthDp = sizeOf(options, AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250f)
        val heightDp = sizeOf(options, AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110f)

        val classic = layout == HeatmapConfig.LAYOUT_CLASSIC
        val tight = !classic && widthDp < TIGHT_WIDTH_DP

        views.setImageViewBitmap(
            R.id.hm_bg,
            CardBitmaps.background(
                (widthDp * density).toInt(),
                (heightDp * density).toInt(),
                RADIUS_DP * density,
                style,
            ),
        )

        val data = HabitCardData.load(
            context,
            HeatmapConfig.habitOf(context, appWidgetId),
            HeatmapConfig.colorOf(context, appWidgetId),
        )

        if (data == null || data.levels.isEmpty()) {
            views.setViewVisibility(R.id.hm_content, View.GONE)
            views.setViewVisibility(R.id.hm_empty, View.VISIBLE)
            views.setTextViewText(
                R.id.hm_empty,
                WidgetText.get(context, "open_to_sync", "Open Streak to sync"),
            )
            views.setTextColor(R.id.hm_empty, style.muted)
            views.setOnClickPendingIntent(R.id.root, openIntent(context, appWidgetId, null))
            return views
        }

        views.setViewVisibility(R.id.hm_content, View.VISIBLE)
        views.setViewVisibility(R.id.hm_empty, View.GONE)
        views.setOnClickPendingIntent(R.id.root, openIntent(context, appWidgetId, data.id))

        val innerHeight = heightDp - PAD_DP * 2

        val gridHeightDp: Float
        if (classic) {
            views.setViewVisibility(R.id.hm_header, View.GONE)
            views.setViewVisibility(R.id.hm_title, View.VISIBLE)
            views.setTextViewText(R.id.hm_title, data.name)
            views.setTextColor(R.id.hm_title, style.content)
            gridHeightDp = innerHeight - CLASSIC_TITLE_DP - GAP_DP
        } else {
            views.setViewVisibility(R.id.hm_title, View.GONE)
            views.setViewVisibility(R.id.hm_header, View.VISIBLE)
            val tileDp = (innerHeight * 0.32f).coerceIn(TILE_MIN_DP, TILE_MAX_DP)
            header(context, views, style, data, appWidgetId, tileDp, density, tight)
            gridHeightDp = innerHeight - tileDp - GAP_DP
        }

        views.setImageViewBitmap(
            R.id.hm_grid,
            CardBitmaps.grid(
                ((widthDp - PAD_DP * 2) * density).toInt(),
                (gridHeightDp * density).toInt(),
                data.levels,
                data.color,
                if (classic) style.cell else null,
            ),
        )
        return views
    }

    private fun header(
        context: Context,
        views: RemoteViews,
        style: CardStyle,
        data: HabitCardData,
        appWidgetId: Int,
        tileDp: Float,
        density: Float,
        tight: Boolean,
    ) {
        val tilePx = (tileDp * density).toInt()
        val habitId = data.id
        val filled = tight && data.doneToday

        setSize(views, R.id.hm_tile, tileDp)
        views.setImageViewBitmap(
            R.id.hm_tile,
            CardBitmaps.tile(
                tilePx,
                if (filled) data.color else CardBitmaps.withAlpha(data.color, 0.20f),
                data.iconPath,
                when {
                    !data.iconTintable -> null
                    filled -> Color.WHITE
                    tight -> data.color
                    else -> style.content
                },
            ),
        )

        views.setTextViewText(R.id.hm_name, data.name)
        views.setTextColor(R.id.hm_name, style.content)
        views.setTextViewTextSize(
            R.id.hm_name,
            TypedValue.COMPLEX_UNIT_SP,
            if (tileDp >= 38f) 17f else 15f,
        )

        if (!tight && data.description.isNotEmpty() && tileDp >= 34f) {
            views.setViewVisibility(R.id.hm_desc, View.VISIBLE)
            views.setTextViewText(R.id.hm_desc, data.description)
            views.setTextColor(R.id.hm_desc, CardBitmaps.withAlpha(style.content, 0.72f))
        } else {
            views.setViewVisibility(R.id.hm_desc, View.GONE)
        }

        if (tight) {
            views.setViewVisibility(R.id.hm_check_touch, View.GONE)
            if (habitId != null) {
                views.setOnClickPendingIntent(
                    R.id.hm_tile_touch,
                    toggleIntent(context, appWidgetId, habitId),
                )
            }
            return
        }

        views.setOnClickPendingIntent(
            R.id.hm_tile_touch,
            openIntent(context, appWidgetId, data.id),
        )
        views.setViewVisibility(
            R.id.hm_check_touch,
            if (habitId != null) View.VISIBLE else View.GONE,
        )
        if (habitId == null) return

        setSize(views, R.id.hm_check, tileDp)
        views.setImageViewBitmap(
            R.id.hm_check,
            CardBitmaps.check(
                tilePx,
                if (data.doneToday) data.color else CardBitmaps.withAlpha(data.color, 0.20f),
                if (data.doneToday) Color.WHITE else data.color,
            ),
        )
        views.setOnClickPendingIntent(
            R.id.hm_check_touch,
            toggleIntent(context, appWidgetId, habitId),
        )
    }

    private fun setSize(views: RemoteViews, id: Int, dp: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        views.setViewLayoutWidth(id, dp, TypedValue.COMPLEX_UNIT_DIP)
        views.setViewLayoutHeight(id, dp, TypedValue.COMPLEX_UNIT_DIP)
    }

    private fun sizeOf(options: Bundle?, key: String, fallback: Float): Float {
        val value = options?.getInt(key, 0) ?: 0
        return if (value > 0) value.toFloat() else fallback
    }

    private fun openIntent(context: Context, appWidgetId: Int, habitId: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (habitId != null) putExtra("openHabitId", habitId)
            setData(Uri.parse("streak://open/$appWidgetId"))
        }
        return PendingIntent.getActivity(
            context,
            appWidgetId * 4,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun toggleIntent(
        context: Context,
        appWidgetId: Int,
        habitId: String,
    ): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_TOGGLE
            putExtra(WidgetActionReceiver.EXTRA_HABIT_ID, habitId)
            putExtra(WidgetActionReceiver.EXTRA_WIDGET_ID, appWidgetId)
            setData(Uri.parse("streak://toggle/$appWidgetId/$habitId"))
        }
        return PendingIntent.getBroadcast(
            context,
            appWidgetId * 4 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

class HabitCardData(
    val id: String?,
    val name: String,
    val description: String,
    val color: Int,
    val iconPath: String,
    val iconTintable: Boolean,
    val kind: Int,
    val incrementAmount: Double,
    val doneToday: Boolean,
    val levels: List<Int>,
) {
    companion object {
        private const val BRAND = 0xFF7C5CFC.toInt()

        fun load(context: Context, habitId: String?, allColor: Int?): HabitCardData? = try {
            val raw = context
                .getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .getString("habits_data", null)
            val root = raw?.let { JSONObject(it) }
            when {
                root == null -> null
                habitId != null -> habitOf(root, habitId)
                else -> everything(context, root, allColor)
            }
        } catch (e: Exception) {
            null
        }

        private fun habitOf(root: JSONObject, habitId: String): HabitCardData? {
            val habits = root.optJSONArray("habits") ?: return null
            for (i in 0 until habits.length()) {
                val habit = habits.getJSONObject(i)
                if (habit.optString("id") == habitId) return from(habit)
            }
            return null
        }

        private fun everything(
            context: Context,
            root: JSONObject,
            allColor: Int?,
        ): HabitCardData = HabitCardData(
            id = null,
            name = WidgetText.get(context, "activity", "Activity"),
            description = "",
            color = allColor ?: BRAND,
            iconPath = root.optString("fallbackIconPath", ""),
            iconTintable = true,
            kind = 0,
            incrementAmount = 1.0,
            doneToday = false,
            levels = levelsOf(root.optJSONArray("heatmap")),
        )

        private fun from(habit: JSONObject): HabitCardData {
            val completions = habit.optJSONArray("completions")
            return HabitCardData(
                id = habit.optString("id"),
                name = habit.optString("name"),
                description = habit.optString("description", ""),
                color = habit.getInt("color"),
                iconPath = habit.optString("iconPath", ""),
                iconTintable = habit.optBoolean("iconTintable", true),
                kind = habit.optInt("kind", 0),
                incrementAmount =
                    habit.optDouble("incrementAmount", 1.0).coerceAtLeast(0.01),
                doneToday = completions != null &&
                    completions.length() >= 7 &&
                    completions.optBoolean(6, false),
                levels = levelsOf(habit.optJSONArray("heatmap")),
            )
        }

        private fun levelsOf(array: JSONArray?): List<Int> {
            if (array == null) return emptyList()
            val usable = array.length() / CardBitmaps.ROWS * CardBitmaps.ROWS
            return List(usable) { array.optInt(it, 0) }
        }
    }
}
