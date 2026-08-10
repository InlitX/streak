package com.streak.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.unit.ColorProvider
import java.io.File
import kotlin.math.min

data class WidgetStyle(
    val background: Color,
    val border: Color?,
    val borderWidth: Int,
    val content: Color,
    val muted: Color,
    val cell: Color,
    val imagePath: String?,
    val scrim: Color,
) {
    companion object {
        fun loadFor(context: Context, id: Int): WidgetStyle {
            val opacity = WidgetConfig.opacity(context, id)
            val border = WidgetConfig.border(context, id)
            val bw = WidgetConfig.borderWidth(context, id)
            val image = WidgetConfig.image(context, id)
            if (WidgetConfig.bgMode(context, id) == 1 &&
                image != null && File(image).exists()
            ) {
                return image(image, opacity, border, bw)
            }
            return from(WidgetConfig.bgFor(context, id), opacity, border, bw)
        }

        fun loadFor(context: Context, glanceId: GlanceId): WidgetStyle =
            try {
                loadFor(context, GlanceAppWidgetManager(context).getAppWidgetId(glanceId))
            } catch (e: Exception) {
                from(WidgetConfig.DEFAULT_BG, 100, false, 2)
            }

        fun from(rgb: Int, opacity: Int, border: Boolean, borderWidth: Int): WidgetStyle {
            val alpha = opacity.coerceIn(0, 100) * 255 / 100
            val bg = Color((alpha shl 24) or (rgb and 0x00FFFFFF))
            val dark = Color(0xFF000000.toInt() or (rgb and 0x00FFFFFF)).luminance() < 0.5f
            val content = if (dark) Color.White else Color(0xFF14141A)
            return WidgetStyle(
                background = bg,
                border = if (border) content.copy(alpha = 0.30f) else null,
                borderWidth = borderWidth,
                content = content,
                muted = content.copy(alpha = 0.55f),
                cell = content.copy(alpha = 0.14f),
                imagePath = null,
                scrim = Color(0x00000000),
            )
        }

        fun image(path: String, opacity: Int, border: Boolean, borderWidth: Int): WidgetStyle {
            val scrim = (100 - opacity.coerceIn(0, 100)) * 255 / 100
            return WidgetStyle(
                background = Color(0x00000000),
                border = if (border) Color(0x4DFFFFFF) else null,
                borderWidth = borderWidth,
                content = Color.White,
                muted = Color(0xB3FFFFFF),
                cell = Color(0x33FFFFFF),
                imagePath = path,
                scrim = Color(0f, 0f, 0f, scrim / 255f),
            )
        }
    }
}

private fun decode(path: String?): Bitmap? {
    if (path.isNullOrEmpty()) return null
    return try {
        if (!File(path).exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 720) sample *= 2
        BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
    } catch (e: Exception) {
        null
    }
}

@Composable
fun WidgetSurface(
    style: WidgetStyle,
    radius: Dp = 20.dp,
    content: @Composable () -> Unit,
) {
    BorderWrap(style, radius) {
        Box(modifier = GlanceModifier.fillMaxSize().cornerRadius(radius)) {
            val bitmap = decode(style.imagePath)
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().cornerRadius(radius),
                )
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(ColorProvider(style.scrim))
                        .cornerRadius(radius),
                ) {}
            } else {
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(ColorProvider(style.background))
                        .cornerRadius(radius),
                ) {}
            }
            content()
        }
    }
}

@Composable
fun BorderWrap(
    style: WidgetStyle,
    radius: Dp = 20.dp,
    content: @Composable () -> Unit,
) {
    val b = style.border
    if (b == null) {
        content()
        return
    }
    val density = LocalContext.current.resources.displayMetrics.density
    val size = LocalSize.current
    val argb = b.toArgb()
    val ring = remember(size, argb, style.borderWidth) {
        ringBitmap(size.width.value, size.height.value, radius.value, style.borderWidth, density, argb)
    }
    Box(modifier = GlanceModifier.fillMaxSize().cornerRadius(radius)) {
        content()
        if (ring != null) {
            Image(
                provider = ImageProvider(ring),
                contentDescription = null,
                contentScale = ContentScale.FillBounds,
                modifier = GlanceModifier.fillMaxSize(),
            )
        }
    }
}

private fun ringBitmap(
    wDp: Float, hDp: Float, radiusDp: Float, widthDp: Int, density: Float, argb: Int,
): Bitmap? {
    val fullW = wDp * density
    val fullH = hDp * density
    if (fullW < 1f || fullH < 1f) return null
    val scale = min(1f, 900f / maxOf(fullW, fullH))
    val w = (fullW * scale).toInt().coerceAtLeast(1)
    val h = (fullH * scale).toInt().coerceAtLeast(1)
    val stroke = widthDp * density * scale
    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = argb
        this.style = Paint.Style.STROKE
        strokeWidth = stroke
    }
    val inset = stroke / 2f
    val r = radiusDp * density * scale
    Canvas(bmp).drawRoundRect(inset, inset, w - inset, h - inset, r, r, paint)
    return bmp
}
