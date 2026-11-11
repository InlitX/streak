package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width

object WidgetScroll {

    const val ACTION = "com.streak.app.SCROLL_WIDGET"
    const val EXTRA_PER = "scrollPer"
    const val EXTRA_TOTAL = "scrollTotal"
    const val EXTRA_DIR = "scrollDir"
    private const val PREFS = "StreakWidgetScroll"
    private const val BUTTON = 30f
    const val FOOTER = 34f

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun offset(context: Context, id: Int, total: Int, per: Int): Int =
        prefs(context).getInt("offset_$id", 0).coerceIn(0, maxOf(0, total - per))

    fun move(context: Context, id: Int, dir: Int, per: Int, total: Int) {
        val now = offset(context, id, total, per)
        val next = (now + dir * per).coerceIn(0, maxOf(0, total - per))
        prefs(context).edit().putInt("offset_$id", next).apply()
    }

    fun forget(context: Context, id: Int) {
        prefs(context).edit().remove("offset_$id").apply()
    }

    fun rows(room: Float, row: Float, gap: Float = 0f): Int = maxOf(1, ((room + gap) / row).toInt())

    fun extra(context: Context, id: Int, shown: Float): Float {
        val tall = AppWidgetManager.getInstance(context).getAppWidgetOptions(id)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        return maxOf(0f, tall - shown)
    }

    private fun intent(context: Context, id: Int, dir: Int, per: Int, total: Int): Intent =
        Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION
            putExtra(WidgetActionReceiver.EXTRA_WIDGET_ID, id)
            putExtra(EXTRA_DIR, dir)
            putExtra(EXTRA_PER, per)
            putExtra(EXTRA_TOTAL, total)
            data = Uri.parse("streak://scroll/$id/$dir")
        }

    private fun arrow(context: Context, color: Int, up: Boolean): Bitmap {
        val density = WidgetDraw.density(context)
        val side = (BUTTON * density).toInt()
        val bitmap = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.style = Paint.Style.FILL
        paint.color = (color and 0x00FFFFFF) or (0x33 shl 24)
        canvas.drawCircle(side / 2f, side / 2f, side / 2f, paint)
        paint.style = Paint.Style.STROKE
        paint.color = color
        paint.strokeWidth = 2.4f * density
        paint.strokeCap = Paint.Cap.ROUND
        paint.strokeJoin = Paint.Join.ROUND
        val c = side / 2f
        val w = 5.5f * density
        val h = 2.8f * density
        val path = Path()
        if (up) {
            path.moveTo(c - w, c + h); path.lineTo(c, c - h); path.lineTo(c + w, c + h)
        } else {
            path.moveTo(c - w, c - h); path.lineTo(c, c + h); path.lineTo(c + w, c - h)
        }
        canvas.drawPath(path, paint)
        return bitmap
    }

    @Composable
    fun Arrows(
        context: Context,
        ink: androidx.compose.ui.graphics.Color,
        appWidgetId: Int,
        density: Float,
        offset: Int,
        per: Int,
        total: Int,
        end: Float,
    ) {
        val up = offset > 0
        val down = offset + per < total
        if (!up && !down) return
        val color = ink.toArgb()
        Box(modifier = GlanceModifier.fillMaxWidth().height(FOOTER.dp).padding(end = end.dp), contentAlignment = Alignment.BottomEnd) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (up) Box(
                    modifier = GlanceModifier.size(BUTTON.dp)
                        .clickable(actionSendBroadcast(intent(context, appWidgetId, -1, per, total))),
                ) { Drawn(arrow(context, color, true), density, "up") }
                if (up && down) Spacer(GlanceModifier.width(6.dp))
                if (down) Box(
                    modifier = GlanceModifier.size(BUTTON.dp)
                        .clickable(actionSendBroadcast(intent(context, appWidgetId, 1, per, total))),
                ) { Drawn(arrow(context, color, false), density, "down") }
            }
        }
    }
}
