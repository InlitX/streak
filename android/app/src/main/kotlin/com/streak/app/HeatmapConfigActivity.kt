package com.streak.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.json.JSONObject

private val bgColor = Color(0xFF101014)
private val cardColor = Color(0xFF1B1B22)
private val brand = Color(0xFF7C5CFC)
private val mutedColor = Color(0xFF9CA3AF)

private data class HabitOption(val id: String?, val name: String, val color: Color)

class HeatmapConfigActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Cancel by default: leaving without a pick shouldn't place the widget.
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val options = loadOptions()
        setContent { Screen(options) { choose(it) } }
    }

    private fun choose(option: HabitOption) {
        HeatmapConfig.setHabit(this, appWidgetId, option.id)

        val id = appWidgetId
        val ctx = applicationContext
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))

        // Backup, survives our process being killed on aggressive OEMs.
        scheduleRefresh(id, 900L, 1)
        scheduleRefresh(id, 2500L, 2)

        // No-op state write marks state dirty so update() recomposes (bare update() is cached).
        lifecycleScope.launch {
            try {
                val glanceId = GlanceAppWidgetManager(ctx).getGlanceIdBy(id)
                updateAppWidgetState<HomeWidgetGlanceState>(
                    ctx, HomeWidgetGlanceStateDefinition(), glanceId,
                ) { it }
                HeatmapWidget().update(ctx, glanceId)
            } catch (_: Exception) {
            }
            finish()
        }
    }

    private fun scheduleRefresh(appWidgetId: Int, delayMs: Long, code: Int) {
        val intent = Intent(this, HeatmapWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }
        val pending = PendingIntent.getBroadcast(
            this,
            appWidgetId * 10 + code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        getSystemService(AlarmManager::class.java).set(
            AlarmManager.RTC,
            System.currentTimeMillis() + delayMs,
            pending,
        )
    }

    private fun loadOptions(): List<HabitOption> {
        val all = listOf(HabitOption(null, "All habits", brand))
        return try {
            val json = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .getString("habits_data", null) ?: return all
            val habits = JSONObject(json).optJSONArray("habits") ?: return all
            all + (0 until habits.length()).map { i ->
                val habit = habits.getJSONObject(i)
                HabitOption(
                    habit.optString("id"),
                    habit.optString("name"),
                    Color(habit.getInt("color"))
                )
            }
        } catch (e: Exception) {
            all
        }
    }
}

@Composable
private fun Screen(options: List<HabitOption>, onPick: (HabitOption) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(bgColor)
            .padding(24.dp)
    ) {
        Text(
            text = "Show activity of",
            color = Color.White,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = "Pick what this widget tracks",
            color = mutedColor,
            fontSize = 14.sp
        )
        Spacer(Modifier.height(20.dp))

        if (options.size == 1) {
            Text(
                text = "No habits yet — open Streak and add one first.",
                color = mutedColor,
                fontSize = 14.sp
            )
        }

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(options) { option -> OptionRow(option) { onPick(option) } }
        }
    }
}

@Composable
private fun OptionRow(option: HabitOption, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(cardColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(14.dp)
                .clip(CircleShape)
                .background(option.color)
        )
        Spacer(Modifier.width(14.dp))
        Text(
            text = option.name,
            color = Color.White,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium
        )
    }
}
