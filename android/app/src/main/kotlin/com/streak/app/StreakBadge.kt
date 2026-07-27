package com.streak.app

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

@Composable
fun StreakBadge(streak: Int, color: Color, style: WidgetStyle) {
    if (streak <= 0) return
    Row(verticalAlignment = Alignment.CenterVertically) {
        Spacer(modifier = GlanceModifier.width(5.dp))
        Image(
            provider = ImageProvider(R.drawable.ic_widget_flame),
            contentDescription = null,
            colorFilter = ColorFilter.tint(ColorProvider(color)),
            modifier = GlanceModifier.size(12.dp)
        )
        Spacer(modifier = GlanceModifier.width(2.dp))
        Text(
            text = if (streak > 999) "999+" else streak.toString(),
            style = TextStyle(
                color = ColorProvider(style.content),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            ),
            maxLines = 1
        )
    }
}
