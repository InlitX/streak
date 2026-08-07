package com.streak.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.Rect
import android.graphics.RectF
import java.io.File
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

object CardBitmaps {

    const val ROWS = 7

    private const val CELL_OF_PITCH = 11f / 13f
    private const val RADIUS_OF_CELL = 3f / 11f
    private const val TILE_RADIUS_RATIO = 12f / 42f
    private const val MAX_PX = 1600f

    fun grid(
        widthPx: Int,
        heightPx: Int,
        levels: List<Int>,
        accent: Int,
        emptyColor: Int?,
    ): Bitmap? {
        if (widthPx < 1 || heightPx < 1 || levels.size < ROWS) return null
        return try {
            val w = min(widthPx, MAX_PX.toInt())
            val h = min(heightPx, MAX_PX.toInt())
            val pitch = h / ROWS.toFloat()
            val cell = pitch * CELL_OF_PITCH
            val gap = pitch - cell
            val fits = ((w + gap) / pitch).toInt().coerceAtLeast(1)
            val weeks = min(fits, levels.size / ROWS)
            val start = (levels.size / ROWS - weeks) * ROWS
            val step = if (weeks > 1) (w - cell) / (weeks - 1) else 0f

            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val radius = cell * RADIUS_OF_CELL

            for (column in 0 until weeks) {
                for (row in 0 until ROWS) {
                    paint.color = levelColor(accent, levels[start + column * ROWS + row], emptyColor)
                    val x = column * step
                    val y = row * pitch
                    canvas.drawRoundRect(RectF(x, y, x + cell, y + cell), radius, radius, paint)
                }
            }
            bitmap
        } catch (e: Exception) {
            null
        }
    }

    fun tile(sizePx: Int, fill: Int, glyphPath: String, glyphTint: Int?): Bitmap? {
        if (sizePx < 1) return null
        return try {
            val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val radius = sizePx * TILE_RADIUS_RATIO
            canvas.drawRoundRect(
                RectF(0f, 0f, sizePx.toFloat(), sizePx.toFloat()),
                radius,
                radius,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = fill },
            )
            val glyph = decode(glyphPath)
            if (glyph != null) {
                val inset = sizePx * 0.225f
                val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
                if (glyphTint != null) {
                    paint.colorFilter = PorterDuffColorFilter(glyphTint, PorterDuff.Mode.SRC_IN)
                }
                canvas.drawBitmap(
                    glyph,
                    Rect(0, 0, glyph.width, glyph.height),
                    RectF(inset, inset, sizePx - inset, sizePx - inset),
                    paint,
                )
            }
            bitmap
        } catch (e: Exception) {
            null
        }
    }

    fun check(sizePx: Int, fill: Int, mark: Int): Bitmap? {
        if (sizePx < 1) return null
        return try {
            val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val radius = sizePx * TILE_RADIUS_RATIO
            canvas.drawRoundRect(
                RectF(0f, 0f, sizePx.toFloat(), sizePx.toFloat()),
                radius,
                radius,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = fill },
            )
            val stroke = sizePx * 0.115f
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = mark
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            val s = sizePx.toFloat()
            canvas.drawLines(
                floatArrayOf(
                    s * 0.28f, s * 0.52f, s * 0.44f, s * 0.68f,
                    s * 0.44f, s * 0.68f, s * 0.73f, s * 0.34f,
                ),
                paint,
            )
            bitmap
        } catch (e: Exception) {
            null
        }
    }

    fun background(
        widthPx: Int,
        heightPx: Int,
        radiusPx: Float,
        style: CardStyle,
    ): Bitmap? {
        if (widthPx < 1 || heightPx < 1) return null
        return try {
            val w = min(widthPx, MAX_PX.toInt())
            val h = min(heightPx, MAX_PX.toInt())
            val scale = w.toFloat() / widthPx
            val radius = radiusPx * scale
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())

            val photo = decode(style.imagePath)
            if (photo != null) {
                val rounded = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                val shaped = Canvas(rounded)
                shaped.drawRoundRect(
                    rect, radius, radius,
                    Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE },
                )
                val src = cropRect(photo, w, h)
                shaped.drawBitmap(
                    photo, src, rect,
                    Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
                        xfermode = android.graphics.PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
                    },
                )
                canvas.drawBitmap(rounded, 0f, 0f, null)
                if (Color.alpha(style.scrim) > 0) {
                    canvas.drawRoundRect(
                        rect, radius, radius,
                        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = style.scrim },
                    )
                }
            } else {
                canvas.drawRoundRect(
                    rect, radius, radius,
                    Paint(Paint.ANTI_ALIAS_FLAG).apply { color = style.background },
                )
            }

            if (style.border != null) {
                val stroke = style.borderWidth * scale
                canvas.drawRoundRect(
                    RectF(
                        stroke / 2f, stroke / 2f,
                        w - stroke / 2f, h - stroke / 2f,
                    ),
                    radius, radius,
                    Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = style.border
                        this.style = Paint.Style.STROKE
                        strokeWidth = stroke
                    },
                )
            }
            bitmap
        } catch (e: Exception) {
            null
        }
    }

    private fun cropRect(photo: Bitmap, w: Int, h: Int): Rect {
        val target = w.toFloat() / h
        val source = photo.width.toFloat() / photo.height
        return if (source > target) {
            val cropped = (photo.height * target).toInt()
            val x = (photo.width - cropped) / 2
            Rect(x, 0, x + cropped, photo.height)
        } else {
            val cropped = (photo.width / target).toInt()
            val y = (photo.height - cropped) / 2
            Rect(0, y, photo.width, y + cropped)
        }
    }

    fun levelFor(kind: Int, count: Double, target: Double): Int = when {
        kind == 1 -> if (count > 0) 0 else 4
        count <= 0 -> 0
        else -> ceil(count / max(1.0, target) * 4).toInt().coerceIn(1, 4)
    }

    private fun levelColor(accent: Int, level: Int, emptyColor: Int?): Int {
        if (level <= 0 && emptyColor != null) {
            return if (level == -1) withAlpha(emptyColor, 0.35f) else emptyColor
        }
        val alpha = when (level) {
            -1 -> 0.08f
            1 -> 0.40f
            2 -> 0.60f
            3 -> 0.80f
            4 -> 1f
            else -> 0.20f
        }
        return withAlpha(accent, alpha)
    }

    fun withAlpha(color: Int, alpha: Float): Int =
        ((alpha.coerceIn(0f, 1f) * 255).toInt() shl 24) or (color and 0x00FFFFFF)

    private fun decode(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        return try {
            if (!File(path).exists()) return null
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (max(bounds.outWidth, bounds.outHeight) / sample > 720) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (e: Exception) {
            null
        }
    }
}
