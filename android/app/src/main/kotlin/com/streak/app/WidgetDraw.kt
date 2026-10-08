package com.streak.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.SweepGradient
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.dp
import androidx.core.graphics.ColorUtils
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.height
import androidx.glance.layout.width
import kotlin.math.cos
import kotlin.math.sin

enum class DayKind { DONE, MISSED, TODAY, REST }

enum class ButtonKind { DONE, TODO, AMOUNT, RELAPSE }

enum class WeekMark { DONE, PART, MISSED, RELAPSE, TODAY, EMPTY, OFF }

object WidgetDraw {

    private const val FONT = "flutter_assets/fonts/GoogleSansFlex.ttf"
    private val GREEN_A = 0xFF6EE78C.toInt()
    private val GREEN_B = 0xFF24B25C.toInt()
    private val faces = HashMap<Int, Typeface>()
    private val cache = LinkedHashMap<String, Bitmap>()

    private fun face(context: Context, weight: Int): Typeface = synchronized(faces) {
        faces.getOrPut(weight) {
            try {
                Typeface.Builder(context.assets, FONT)
                    .setFontVariationSettings("'wght' $weight, 'ROND' 100, 'opsz' 14")
                    .build() ?: Typeface.DEFAULT_BOLD
            } catch (e: Exception) {
                Typeface.DEFAULT_BOLD
            }
        }
    }

    fun density(context: Context): Float = context.resources.displayMetrics.density

    private fun scale(context: Context): Float =
        density(context) * context.resources.configuration.fontScale.coerceIn(1f, 1.3f)

    private fun remember(key: String, make: () -> Bitmap): Bitmap {
        synchronized(cache) { cache[key]?.let { return it } }
        val bitmap = make()
        synchronized(cache) {
            if (cache.size > 160) cache.remove(cache.keys.first())
            cache[key] = bitmap
        }
        return bitmap
    }

    private fun paint(context: Context, sizeSp: Float, color: Int, weight: Int) =
        TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = face(context, weight)
            textSize = sizeSp * scale(context)
            this.color = color
        }

    fun text(
        context: Context,
        value: String,
        sizeSp: Float,
        color: Color,
        weight: Int,
        maxWidthDp: Float = 10_000f,
        strike: Boolean = false,
    ): Bitmap {
        val argb = color.toArgb()
        val key = "t:$value:$sizeSp:$argb:$weight:${maxWidthDp.toInt()}:$strike:${scale(context)}"
        return remember(key) {
            val paint = paint(context, sizeSp, argb, weight)
            val shown = TextUtils.ellipsize(
                value, paint, maxWidthDp * density(context), TextUtils.TruncateAt.END,
            ).toString()
            val metrics = paint.fontMetrics
            val width = paint.measureText(shown).coerceAtLeast(1f)
            val height = metrics.descent - metrics.ascent
            val bitmap = Bitmap.createBitmap(
                (width + 2).toInt(), height.toInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888,
            )
            val canvas = Canvas(bitmap)
            canvas.drawText(shown, 1f, -metrics.ascent, paint)
            if (strike) {
                val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.color = argb
                    strokeWidth = density(context) * 1.3f
                }
                val y = -metrics.ascent - paint.textSize * 0.32f
                canvas.drawLine(1f, y, width + 1, y, line)
            }
            bitmap
        }
    }

    fun ring(
        context: Context,
        progress: Float,
        sizeDp: Float,
        strokeDp: Float,
        ink: Color,
        label: String? = null,
        labelSp: Float = 12f,
    ): Bitmap {
        val p = progress.coerceIn(0f, 1f)
        val key = "r:${(p * 100).toInt()}:$sizeDp:$strokeDp:${ink.toArgb()}:$label:$labelSp:${scale(context)}"
        return remember(key) {
            val d = density(context)
            val px = (sizeDp * d).toInt().coerceAtLeast(1)
            val stroke = strokeDp * d
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val inset = stroke / 2 + d
            val rect = RectF(inset, inset, px - inset, px - inset)
            val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
                color = ink.copy(alpha = 0.16f).toArgb()
            }
            canvas.drawArc(rect, 0f, 360f, false, arc)
            if (p > 0f) {
                val center = px / 2f
                val sweep = SweepGradient(center, center, intArrayOf(GREEN_A, GREEN_B), floatArrayOf(0f, p))
                sweep.setLocalMatrix(Matrix().apply { setRotate(-92f, center, center) })
                arc.shader = sweep
                arc.color = GREEN_A
                canvas.drawArc(rect, -90f, 360f * p, false, arc)
                val angle = Math.toRadians((-90f + 360f * p).toDouble())
                val radius = (px - inset * 2) / 2f
                val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xE6FFFFFF.toInt() }
                canvas.drawCircle(
                    center + radius * cos(angle).toFloat(),
                    center + radius * sin(angle).toFloat(),
                    stroke * 0.22f,
                    dot,
                )
            }
            if (label != null) {
                val text = paint(context, labelSp, ink.toArgb(), 800).apply { textAlign = Paint.Align.CENTER }
                val metrics = text.fontMetrics
                canvas.drawText(label, px / 2f, px / 2f - (metrics.ascent + metrics.descent) / 2f, text)
            }
            bitmap
        }
    }

    fun chip(
        context: Context,
        widthDp: Float,
        heightDp: Float,
        kind: DayKind,
        label: String,
        ink: Color,
        progress: Float,
    ): Bitmap {
        val key = "c:$widthDp:$heightDp:$kind:$label:${ink.toArgb()}:${(progress * 100).toInt()}:${scale(context)}"
        return remember(key) {
            val d = density(context)
            val w = (widthDp * d).toInt().coerceAtLeast(1)
            val h = (heightDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val today = kind == DayKind.TODAY
            val on = if (ColorUtils.calculateLuminance(ink.toArgb()) > 0.5) Color(0xFF14141A) else Color.White
            val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = ink.copy(alpha = if (today) 0.95f else 0.07f).toArgb()
            }
            canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), 16 * d, 16 * d, fill)
            val cx = w / 2f
            val cy = h * 0.4f
            val mark = 20 * d
            when (kind) {
                DayKind.DONE -> {
                    val g = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        shader = LinearGradient(0f, cy - mark / 2, 0f, cy + mark / 2, GREEN_A, GREEN_B, Shader.TileMode.CLAMP)
                    }
                    canvas.drawCircle(cx, cy, mark / 2, g)
                    glyph(context, canvas, R.drawable.ic_widget_check, cx, cy, mark * 0.62f, android.graphics.Color.WHITE)
                }
                DayKind.MISSED -> {
                    canvas.drawCircle(cx, cy, mark / 2, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x38FF5448 })
                    centered(canvas, paint(context, 13f, 0xFFFF5448.toInt(), 900), "!", cx, cy)
                }
                DayKind.TODAY -> {
                    val ring = ring(context, progress, 20f, 2.8f, on)
                    canvas.drawBitmap(ring, cx - ring.width / 2f, cy - ring.height / 2f, null)
                }
                DayKind.REST -> centered(canvas, paint(context, 10.5f, ink.copy(alpha = 0.32f).toArgb(), 800), "zz", cx, cy)
            }
            val labelColor = if (today) on else ink.copy(alpha = 0.62f)
            centered(canvas, paint(context, 10.5f, labelColor.toArgb(), if (today) 800 else 650), label, cx, h * 0.8f)
            bitmap
        }
    }

    fun button(context: Context, sizeDp: Float, color: Color, kind: ButtonKind, fill: Float, ink: Color): Bitmap {
        val key = "b:$sizeDp:${color.toArgb()}:$kind:${(fill * 100).toInt()}:${ink.toArgb()}"
        return remember(key) {
            val d = density(context)
            val px = (sizeDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val r = px * 0.34f
            val rect = RectF(0f, 0f, px.toFloat(), px.toFloat())
            val argb = color.toArgb()
            val gradient = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    0f, 0f, 0f, px.toFloat(),
                    ColorUtils.blendARGB(argb, android.graphics.Color.WHITE, 0.18f),
                    ColorUtils.blendARGB(argb, android.graphics.Color.BLACK, 0.06f),
                    Shader.TileMode.CLAMP,
                )
            }
            val c = px / 2f
            when (kind) {
                ButtonKind.DONE -> {
                    canvas.drawRoundRect(rect, r, r, gradient)
                    glyph(context, canvas, R.drawable.ic_widget_check, c, c, px * 0.56f, CardBitmaps.inkOn(argb))
                }
                ButtonKind.AMOUNT -> {
                    canvas.drawRoundRect(rect, r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color.copy(alpha = 0.2f).toArgb() })
                    canvas.save()
                    canvas.clipRect(0f, px * (1f - fill.coerceIn(0f, 1f)), px.toFloat(), px.toFloat())
                    canvas.drawRoundRect(rect, r, r, gradient)
                    canvas.restore()
                    centered(canvas, paint(context, sizeDp * 0.6f, if (fill >= 0.5f) CardBitmaps.inkOn(argb) else android.graphics.Color.WHITE, 700), "+", c, c)
                }
                ButtonKind.TODO -> {
                    canvas.drawRoundRect(rect, r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color.copy(alpha = 0.14f).toArgb() })
                    val stroke = 2 * d
                    val inner = RectF(stroke / 2, stroke / 2, px - stroke / 2, px - stroke / 2)
                    canvas.drawRoundRect(inner, r - stroke / 2, r - stroke / 2, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        style = Paint.Style.STROKE
                        strokeWidth = stroke
                        this.color = color.copy(alpha = 0.75f).toArgb()
                    })
                }
                ButtonKind.RELAPSE -> {
                    canvas.drawRoundRect(rect, r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color.copy(alpha = 0.18f).toArgb() })
                    glyph(context, canvas, R.drawable.ic_widget_cross, c, c, px * 0.56f, ink.toArgb())
                }
            }
            bitmap
        }
    }

    fun roundCheck(context: Context, sizeDp: Float, ink: Color, done: Boolean): Bitmap {
        val key = "k:$sizeDp:${ink.toArgb()}:$done"
        return remember(key) {
            val d = density(context)
            val px = (sizeDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val c = px / 2f
            if (done) {
                canvas.drawCircle(c, c, c, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(0f, 0f, 0f, px.toFloat(), GREEN_A, GREEN_B, Shader.TileMode.CLAMP)
                })
                glyph(context, canvas, R.drawable.ic_widget_check, c, c, px * 0.58f, android.graphics.Color.WHITE)
            } else {
                val stroke = 2 * d
                canvas.drawCircle(c, c, c - stroke / 2 - d / 2, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = stroke
                    color = ink.copy(alpha = 0.45f).toArgb()
                })
            }
            bitmap
        }
    }

    fun bar(context: Context, widthDp: Float, heightDp: Float, value: Float, ink: Color): Bitmap {
        val key = "bar:$widthDp:$heightDp:${(value * 100).toInt()}:${ink.toArgb()}"
        return remember(key) {
            val d = density(context)
            val w = (widthDp * d).toInt().coerceAtLeast(1)
            val h = (heightDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val r = w / 2f
            canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = ink.copy(alpha = 0.12f).toArgb()
            })
            if (value > 0f) {
                val top = h - maxOf(w.toFloat(), h * value.coerceIn(0f, 1f))
                canvas.drawRoundRect(RectF(0f, top, w.toFloat(), h.toFloat()), r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(0f, top, 0f, h.toFloat(), GREEN_A, GREEN_B, Shader.TileMode.CLAMP)
                })
            }
            bitmap
        }
    }

    fun pill(context: Context, sizeDp: Float, letter: String, ink: Color): Bitmap {
        val key = "pill:$sizeDp:$letter:${ink.toArgb()}:${scale(context)}"
        return remember(key) {
            val px = (sizeDp * density(context)).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val c = px / 2f
            canvas.drawCircle(c, c, c, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ink.copy(alpha = 0.95f).toArgb() })
            val on = if (ColorUtils.calculateLuminance(ink.toArgb()) > 0.5) 0xFF14141A.toInt() else android.graphics.Color.WHITE
            centered(canvas, paint(context, 10.5f, on, 800), letter, c, c)
            bitmap
        }
    }

    fun band(
        context: Context,
        widthDp: Float,
        heightDp: Float,
        ink: Color,
        openTop: Boolean = false,
        openBottom: Boolean = false,
    ): Bitmap {
        val key = "band:$widthDp:$heightDp:${ink.toArgb()}:$openTop:$openBottom"
        return remember(key) {
            val d = density(context)
            val w = (widthDp * d).toInt().coerceAtLeast(1)
            val h = (heightDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val r = w / 2f
            val rect = RectF(
                d / 2,
                if (openTop) -w.toFloat() else d / 2,
                w - d / 2,
                if (openBottom) h + w.toFloat() else h - d / 2,
            )
            canvas.drawRoundRect(rect, r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ink.copy(alpha = 0.12f).toArgb() })
            canvas.drawRoundRect(rect, r, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = d
                color = ink.copy(alpha = 0.22f).toArgb()
            })
            bitmap
        }
    }

    fun dot(context: Context, sizeDp: Float, color: Color, mark: WeekMark, fill: Float, ink: Color): Bitmap {
        val key = "dot:$sizeDp:${color.toArgb()}:$mark:${(fill * 100).toInt()}:${ink.toArgb()}"
        return remember(key) {
            val d = density(context)
            val px = (sizeDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val c = px / 2f
            val argb = color.toArgb()
            val gradient = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    0f, 0f, 0f, px.toFloat(),
                    ColorUtils.blendARGB(argb, android.graphics.Color.WHITE, 0.2f),
                    ColorUtils.blendARGB(argb, android.graphics.Color.BLACK, 0.06f),
                    Shader.TileMode.CLAMP,
                )
            }
            val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
            when (mark) {
                WeekMark.DONE -> {
                    canvas.drawCircle(c, c, c, gradient)
                    glyph(context, canvas, R.drawable.ic_widget_check, c, c, px * 0.58f, CardBitmaps.inkOn(argb))
                }
                WeekMark.PART -> {
                    canvas.drawCircle(c, c, c, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color.copy(alpha = 0.18f).toArgb() })
                    canvas.save()
                    canvas.clipRect(0f, px * (1f - fill.coerceIn(0f, 1f)), px.toFloat(), px.toFloat())
                    canvas.drawCircle(c, c, c, gradient)
                    canvas.restore()
                }
                WeekMark.RELAPSE -> {
                    canvas.drawCircle(c, c, c, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = 0x24FF5448 })
                    glyph(context, canvas, R.drawable.ic_widget_cross, c, c, px * 0.5f, 0xCCFF5448.toInt())
                }
                WeekMark.TODAY -> {
                    canvas.drawCircle(c, c, c, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color.copy(alpha = 0.14f).toArgb() })
                    ring.strokeWidth = 2 * d
                    ring.color = color.copy(alpha = 0.9f).toArgb()
                    canvas.drawCircle(c, c, c - d, ring)
                }
                WeekMark.EMPTY, WeekMark.MISSED -> {
                    ring.strokeWidth = 1.6f * d
                    ring.color = ink.copy(alpha = 0.16f).toArgb()
                    canvas.drawCircle(c, c, c - 0.8f * d, ring)
                }
                WeekMark.OFF -> canvas.drawCircle(c, c, px * 0.09f, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.color = ink.copy(alpha = 0.22f).toArgb()
                })
            }
            bitmap
        }
    }

    private fun centered(canvas: Canvas, paint: Paint, value: String, cx: Float, cy: Float) {
        paint.textAlign = Paint.Align.CENTER
        val metrics = paint.fontMetrics
        canvas.drawText(value, cx, cy - (metrics.ascent + metrics.descent) / 2f, paint)
    }

    private fun glyph(context: Context, canvas: Canvas, res: Int, cx: Float, cy: Float, size: Float, color: Int) {
        val drawable = context.getDrawable(res)?.mutate() ?: return
        drawable.colorFilter = PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN)
        drawable.setBounds((cx - size / 2).toInt(), (cy - size / 2).toInt(), (cx + size / 2).toInt(), (cy + size / 2).toInt())
        drawable.draw(canvas)
    }
}

@Composable
fun Drawn(bitmap: Bitmap, density: Float, description: String? = null) {
    Image(
        provider = ImageProvider(bitmap),
        contentDescription = description,
        modifier = GlanceModifier
            .width((bitmap.width / density).dp)
            .height((bitmap.height / density).dp),
    )
}
