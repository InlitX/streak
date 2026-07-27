package com.streak.app

import android.content.Context
import android.graphics.Color
import java.io.File

data class CardStyle(
    val background: Int,
    val border: Int?,
    val borderWidth: Int,
    val content: Int,
    val muted: Int,
    val cell: Int,
    val imagePath: String?,
    val scrim: Int,
) {
    companion object {
        fun loadFor(context: Context, id: Int): CardStyle {
            val opacity = WidgetConfig.opacity(context, id)
            val border = WidgetConfig.border(context, id)
            val width = WidgetConfig.borderWidth(context, id)
            val image = WidgetConfig.image(context, id)
            if (WidgetConfig.bgMode(context, id) == 1 && image != null && File(image).exists()) {
                val scrim = (100 - opacity.coerceIn(0, 100)) * 255 / 100
                return CardStyle(
                    background = Color.TRANSPARENT,
                    border = if (border) Color.argb(77, 255, 255, 255) else null,
                    borderWidth = width,
                    content = Color.WHITE,
                    muted = Color.argb(179, 255, 255, 255),
                    cell = Color.argb(51, 255, 255, 255),
                    imagePath = image,
                    scrim = Color.argb(scrim, 0, 0, 0),
                )
            }
            return from(WidgetConfig.bg(context, id), opacity, border, width)
        }

        fun from(rgb: Int, opacity: Int, border: Boolean, borderWidth: Int): CardStyle {
            val alpha = opacity.coerceIn(0, 100) * 255 / 100
            val solid = 0xFF000000.toInt() or (rgb and 0x00FFFFFF)
            val dark = luminance(solid) < 0.5f
            val content = if (dark) Color.WHITE else 0xFF14141A.toInt()
            return CardStyle(
                background = (alpha shl 24) or (rgb and 0x00FFFFFF),
                border = if (border) CardBitmaps.withAlpha(content, 0.30f) else null,
                borderWidth = borderWidth,
                content = content,
                muted = CardBitmaps.withAlpha(content, 0.55f),
                cell = CardBitmaps.withAlpha(content, 0.14f),
                imagePath = null,
                scrim = Color.TRANSPARENT,
            )
        }

        private fun luminance(color: Int): Float {
            val r = Color.red(color) / 255f
            val g = Color.green(color) / 255f
            val b = Color.blue(color) / 255f
            return 0.2126f * r + 0.7152f * g + 0.0722f * b
        }
    }
}
