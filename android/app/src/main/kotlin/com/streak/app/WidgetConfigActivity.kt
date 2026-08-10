package com.streak.app

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.File

private val screenBg = Color(0xFF0D0D11)
private val cardColor = Color(0xFF1B1B22)
private val brand = Color(0xFF7C5CFC)
private val mutedColor = Color(0xFF9CA3AF)

private val swatches = listOf(
    0x101014, 0x1B1B22, 0x3A3A44, 0xF2F2F5, 0x7C5CFC, 0x2196F3, 0x00BCD4,
    0x009688, 0x4CAF50, 0xFFC107, 0xFF9800, 0xF44336, 0xE91E63, 0x607D8B,
)

private enum class WType { HABIT, TODAY, STATS, HEATMAP }

private data class HabitOption(val id: String?, val name: String, val color: Color)

class WidgetConfigActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var providerClass = ""
    private var type = WType.HABIT

    private val imageState = mutableStateOf<String?>(null)
    private val bgModeState = mutableStateOf(0)
    private var originalImage: String? = null

    private val pickImage =
        registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
            uri?.let { copyToStorage(it) }?.let { newPath ->
                val prev = imageState.value
                if (prev != null && prev != originalImage) WidgetConfig.deleteImage(this, prev)
                imageState.value = newPath
                bgModeState.value = 1
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        providerClass = AppWidgetManager.getInstance(this)
            .getAppWidgetInfo(appWidgetId)?.provider?.className ?: ""
        type = typeOf(providerClass)

        originalImage = WidgetConfig.image(this, appWidgetId)
        imageState.value = originalImage
        bgModeState.value = WidgetConfig.bgMode(this, appWidgetId)

        setContent {
            Screen(
                habits = if (type == WType.HEATMAP) loadOptions() else emptyList(),
                initialBg = WidgetConfig.bg(this, appWidgetId),
                initialOpacity = WidgetConfig.opacity(this, appWidgetId),
                initialBorder = WidgetConfig.border(this, appWidgetId),
                initialBorderWidth = WidgetConfig.borderWidth(this, appWidgetId),
                initialHabit = HeatmapConfig.habitOf(this, appWidgetId),
                initialAllColor = HeatmapConfig.colorOf(this, appWidgetId),
                initialLayout = HeatmapConfig.layoutOf(this, appWidgetId),
                initialFollowSystem = WidgetConfig.followSystem(this, appWidgetId),
                initialBgLight = WidgetConfig.bgLight(this, appWidgetId),
                isEdit = WidgetConfig.exists(this, appWidgetId),
            )
        }
    }

    private fun typeOf(name: String) = when {
        name.contains("Today") -> WType.TODAY
        name.contains("Stats") -> WType.STATS
        name.contains("Heatmap") -> WType.HEATMAP
        else -> WType.HABIT
    }

    private fun tr(key: String, fallback: String) = WidgetText.get(this, key, fallback)

    private fun trf(key: String, fallback: String, vararg subs: Pair<String, String>) =
        WidgetText.format(this, key, fallback, *subs)

    private fun save(
        bg: Int, opacity: Int, border: Boolean, borderWidth: Int,
        habitId: String?, allColor: Int, layout: Int,
        followSystem: Boolean, bgLight: Int,
    ) {
        val image = if (bgModeState.value == 1) imageState.value else null
        WidgetConfig.set(
            this, appWidgetId, bg, opacity, border, borderWidth,
            if (image != null) 1 else 0, image, followSystem, bgLight,
        )
        if (image != originalImage) WidgetConfig.deleteImage(this, originalImage)
        if (type == WType.HEATMAP) {
            HeatmapConfig.setHabit(this, appWidgetId, habitId)
            HeatmapConfig.setColor(this, appWidgetId, if (habitId == null) allColor else null)
            HeatmapConfig.setLayout(this, appWidgetId, layout)
        }

        val id = appWidgetId
        val ctx = applicationContext
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))
        if (type == WType.HEATMAP) {
            HeatmapRenderer.update(ctx, AppWidgetManager.getInstance(ctx), id)
            finish()
            return
        }
        scheduleRefresh(id, 900L, 1)
        scheduleRefresh(id, 2500L, 2)

        lifecycleScope.launch {
            try {
                val glanceId = GlanceAppWidgetManager(ctx).getGlanceIdBy(id)
                updateAppWidgetState<HomeWidgetGlanceState>(
                    ctx, HomeWidgetGlanceStateDefinition(), glanceId,
                ) { it }
                widgetFor(type).update(ctx, glanceId)
            } catch (_: Exception) {
            }
            finish()
        }
    }

    private fun widgetFor(t: WType): GlanceAppWidget = when (t) {
        WType.TODAY -> TodayWidget()
        WType.STATS -> StatsWidget()
        WType.HEATMAP, WType.HABIT -> HabitWidget()
    }

    private fun copyToStorage(uri: Uri): String? = try {
        val dir = File(filesDir, "widget_images").apply { mkdirs() }
        val file = File(dir, "w_${appWidgetId}_${System.currentTimeMillis()}.jpg")
        contentResolver.openInputStream(uri)?.use { input ->
            file.outputStream().use { input.copyTo(it) }
        }
        file.absolutePath
    } catch (e: Exception) {
        null
    }

    private fun scheduleRefresh(id: Int, delayMs: Long, code: Int) {
        if (providerClass.isEmpty()) return
        val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
            component = ComponentName(this@WidgetConfigActivity, providerClass)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(id))
        }
        val pending = PendingIntent.getBroadcast(
            this, id * 10 + code, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        getSystemService(AlarmManager::class.java)
            .set(AlarmManager.RTC, System.currentTimeMillis() + delayMs, pending)
    }

    private fun loadOptions(): List<HabitOption> {
        val all = listOf(HabitOption(null, tr("cfg_all_habits", "All habits"), brand))
        return try {
            val json = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .getString("habits_data", null) ?: return all
            val habits = JSONObject(json).optJSONArray("habits") ?: return all
            all + (0 until habits.length()).map { i ->
                val h = habits.getJSONObject(i)
                HabitOption(h.optString("id"), h.optString("name"), Color(h.getInt("color")))
            }
        } catch (e: Exception) {
            all
        }
    }

    @Composable
    private fun Screen(
        habits: List<HabitOption>,
        initialBg: Int,
        initialOpacity: Int,
        initialBorder: Boolean,
        initialBorderWidth: Int,
        initialHabit: String?,
        initialAllColor: Int?,
        initialLayout: Int,
        initialFollowSystem: Boolean,
        initialBgLight: Int,
        isEdit: Boolean,
    ) {
        var bg by remember { mutableStateOf(initialBg) }
        var opacity by remember { mutableStateOf(initialOpacity) }
        var border by remember { mutableStateOf(initialBorder) }
        var borderWidth by remember { mutableStateOf(initialBorderWidth) }
        var habitId by remember { mutableStateOf(initialHabit) }
        var allColor by remember { mutableStateOf(initialAllColor ?: brand.toArgb()) }
        var layout by remember { mutableStateOf(initialLayout) }
        var custom by remember { mutableStateOf(false) }
        var followSystem by remember { mutableStateOf(initialFollowSystem) }
        var bgLight by remember { mutableStateOf(initialBgLight) }
        var lightCustom by remember { mutableStateOf(false) }
        val mode by bgModeState
        val image by imageState

        val night = WidgetConfig.isNight(this)
        val shown = if (followSystem && !night) bgLight else bg
        val style = if (mode == 1 && image != null) {
            WidgetStyle.image(image!!, opacity, border, borderWidth)
        } else {
            WidgetStyle.from(shown, opacity, border, borderWidth)
        }

        Column(modifier = Modifier.fillMaxSize().background(screenBg)) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp),
            ) {
                Spacer(Modifier.height(22.dp))
                Text(
                    tr("cfg_title", "Customize widget"),
                    color = Color.White, fontSize = 25.sp, fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.height(18.dp))
                Preview(style, image.takeIf { mode == 1 }, layout, habitId, allColor)

                if (type == WType.HEATMAP) {
                    Spacer(Modifier.height(18.dp))
                    Segmented(
                        left = tr("cfg_style_classic", "Classic"),
                        right = tr("cfg_style_card", "Card"),
                        selected = if (layout == HeatmapConfig.LAYOUT_CARD) 1 else 0,
                        onLeft = { layout = HeatmapConfig.LAYOUT_CLASSIC },
                        onRight = { layout = HeatmapConfig.LAYOUT_CARD },
                    )
                }

                Spacer(Modifier.height(14.dp))
                Section(tr("cfg_color", "Color")) {
                    Segmented(
                        left = tr("cfg_color", "Color"),
                        right = tr("cfg_image", "Image"),
                        selected = mode,
                        onLeft = { bgModeState.value = 0 },
                        onRight = {
                            if (image != null) bgModeState.value = 1 else pickImage.launch("image/*")
                        },
                    )
                    Spacer(Modifier.height(16.dp))
                    if (mode == 1) {
                        FilledButton(
                            if (image == null) tr("cfg_choose_image", "Choose image")
                            else tr("cfg_change_image", "Change image"),
                            Color(0xFF26262F),
                        ) { pickImage.launch("image/*") }
                    } else {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                tr("cfg_follow_system", "Follow system theme"),
                                color = Color.White, fontSize = 15.sp,
                                fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f),
                            )
                            Switch(
                                checked = followSystem,
                                onCheckedChange = { followSystem = it },
                                colors = SwitchDefaults.colors(checkedTrackColor = brand),
                            )
                        }
                        Spacer(Modifier.height(14.dp))
                        if (followSystem) {
                            Label(tr("cfg_dark_color", "Dark theme"))
                            Spacer(Modifier.height(10.dp))
                        }
                        Swatches(bg, custom) { bg = it; custom = false }
                        Spacer(Modifier.height(14.dp))
                        Chip(tr("cfg_custom_color", "Custom color"), custom) { custom = !custom }
                        if (custom) {
                            Spacer(Modifier.height(12.dp))
                            HsvPicker(bg) { bg = it }
                        }
                        if (followSystem) {
                            Spacer(Modifier.height(20.dp))
                            Label(tr("cfg_light_color", "Light theme"))
                            Spacer(Modifier.height(10.dp))
                            Swatches(bgLight, lightCustom) { bgLight = it; lightCustom = false }
                            Spacer(Modifier.height(14.dp))
                            Chip(tr("cfg_custom_color", "Custom color"), lightCustom) {
                                lightCustom = !lightCustom
                            }
                            if (lightCustom) {
                                Spacer(Modifier.height(12.dp))
                                HsvPicker(bgLight) { bgLight = it }
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    SliderRow(
                        label(tr("cfg_opacity", "Opacity")),
                        "$opacity%",
                        opacity.toFloat(),
                        0f..100f,
                    ) { opacity = it.toInt() }
                }

                Spacer(Modifier.height(14.dp))
                Section(tr("cfg_border", "Border")) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            tr("cfg_border", "Border"), color = Color.White, fontSize = 15.sp,
                            fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f),
                        )
                        Switch(
                            checked = border, onCheckedChange = { border = it },
                            colors = SwitchDefaults.colors(checkedTrackColor = brand),
                        )
                    }
                    if (border) {
                        Spacer(Modifier.height(6.dp))
                        SliderRow(
                            label(tr("cfg_thickness", "Thickness")),
                            "${borderWidth}dp",
                            borderWidth.toFloat(),
                            1f..8f,
                        ) { borderWidth = it.toInt() }
                    }
                }

                if (habits.isNotEmpty()) {
                    Spacer(Modifier.height(14.dp))
                    Section(tr("cfg_show_activity", "Show activity of")) {
                        habits.forEachIndexed { index, o ->
                            if (index > 0) Spacer(Modifier.height(8.dp))
                            HabitRow(o, o.id == habitId) { habitId = o.id }
                        }
                        if (habitId == null) {
                            Spacer(Modifier.height(18.dp))
                            Label(tr("cfg_dot_color", "Dot color"))
                            Spacer(Modifier.height(10.dp))
                            Swatches(allColor, custom = false) {
                                allColor = 0xFF000000.toInt() or it
                            }
                        }
                    }
                }

                Spacer(Modifier.height(24.dp))
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF141419))
                    .padding(horizontal = 20.dp, vertical = 14.dp),
            ) {
                FilledButton(
                    if (isEdit) tr("cfg_save", "Save") else tr("cfg_add", "Add widget"),
                    brand, height = 54.dp, bold = true,
                ) {
                    save(
                        bg, opacity, border, borderWidth, habitId, allColor, layout,
                        followSystem, bgLight,
                    )
                }
                Box(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                        .clickable {
                            bg = WidgetConfig.DEFAULT_BG
                            bgLight = WidgetConfig.DEFAULT_BG_LIGHT
                            followSystem = false
                            opacity = 100
                            border = false
                            borderWidth = 2
                            custom = false
                            lightCustom = false
                            allColor = brand.toArgb()
                            layout = HeatmapConfig.LAYOUT_CLASSIC
                            bgModeState.value = 0
                            imageState.value = null
                        }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        tr("cfg_reset", "Reset to default"),
                        color = mutedColor, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    )
                }
            }
        }
    }

    @Composable
    private fun Section(title: String, content: @Composable () -> Unit) = Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(cardColor)
            .padding(18.dp),
    ) {
        Text(
            title.uppercase(),
            color = mutedColor,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(14.dp))
        content()
    }

    @Composable
    private fun Segmented(
        left: String,
        right: String,
        selected: Int,
        onLeft: () -> Unit,
        onRight: () -> Unit,
    ) = Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFF26262F))
            .padding(4.dp),
    ) {
        listOf(left to onLeft, right to onRight).forEachIndexed { index, (label, action) ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(11.dp))
                    .background(if (selected == index) brand else Color.Transparent)
                    .clickable(onClick = action)
                    .padding(vertical = 11.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label,
                    color = if (selected == index) Color.White else mutedColor,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }

    @Composable
    private fun SliderRow(
        title: String,
        value: String,
        current: Float,
        range: ClosedFloatingPointRange<Float>,
        onChange: (Float) -> Unit,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                title, color = Color.White, fontSize = 15.sp,
                fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f),
            )
            Box(
                Modifier.clip(RoundedCornerShape(8.dp)).background(Color(0xFF26262F))
                    .padding(horizontal = 10.dp, vertical = 4.dp),
            ) {
                Text(value, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }
        ThemedSlider(current, range, onChange)
    }

    @Composable
    private fun Preview(
        style: WidgetStyle,
        imagePath: String?,
        layout: Int,
        habitId: String?,
        allColor: Int,
    ) = Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        val frame = if (type == WType.STATS) {
            Modifier.size(152.dp)
        } else {
            Modifier.fillMaxWidth().height(140.dp)
        }
        Box(
            modifier = frame
                .clip(RoundedCornerShape(20.dp))
                .background(style.background)
                .then(
                    style.border?.let {
                        Modifier.border(style.borderWidth.dp, it, RoundedCornerShape(20.dp))
                    } ?: Modifier
                ),
        ) {
            val bmp = remember(imagePath) {
                imagePath?.let {
                    try {
                        val b = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                        BitmapFactory.decodeFile(it, b)
                        var s = 1
                        while (maxOf(b.outWidth, b.outHeight) / s > 720) s *= 2
                        BitmapFactory.decodeFile(it, BitmapFactory.Options().apply { inSampleSize = s })
                            ?.asImageBitmap()
                    } catch (e: Exception) {
                        null
                    }
                }
            }
            if (bmp != null) {
                Image(bmp, null, Modifier.matchParentSize(), contentScale = ContentScale.Crop)
                Box(Modifier.matchParentSize().background(style.scrim))
            }
            Box(Modifier.padding(14.dp)) {
                when (type) {
                    WType.HABIT -> HabitPreview(style)
                    WType.TODAY -> TodayPreview(style)
                    WType.STATS -> StatsPreview(style)
                    WType.HEATMAP -> LivePreview(style, layout, habitId, allColor)
                }
            }
        }
    }

    @Composable
    private fun HabitPreview(s: WidgetStyle) = Column(
        Modifier.fillMaxSize(), verticalArrangement = Arrangement.SpaceEvenly,
    ) {
        listOf(tr("demo_read", "Read"), tr("demo_run", "Run"), tr("demo_water", "Water")).forEach { name ->
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(name, color = s.content, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.width(60.dp))
                Row(Modifier.weight(1f), horizontalArrangement = Arrangement.SpaceBetween) {
                    repeat(7) { i -> Dot(if (i % 2 == 0) brand else s.cell, 13.dp, 4.dp) }
                }
            }
        }
    }

    @Composable
    private fun TodayPreview(s: WidgetStyle) = Column(
        Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center,
    ) {
        Text(trf("today_progress", "Today  2/3", "{done}" to "2", "{total}" to "3"), color = s.content, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        listOf(tr("demo_read", "Read") to true, tr("demo_run", "Run") to false).forEach { (name, done) ->
            Row(Modifier.fillMaxWidth().padding(vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Text(name, color = s.content, fontSize = 13.sp, modifier = Modifier.weight(1f))
                Dot(if (done) brand else s.cell, 22.dp, 8.dp)
            }
        }
    }

    @Composable
    private fun StatsPreview(s: WidgetStyle) = Column(Modifier.fillMaxSize()) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("🔥", fontSize = 11.sp)
            Spacer(Modifier.width(6.dp))
            Text(
                "S T R E A K", color = s.muted, fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
            )
        }
        Spacer(Modifier.height(6.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Text("2", color = s.content, fontSize = 34.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(5.dp))
            Text("/ 3", color = s.muted, fontSize = 14.sp, fontWeight = FontWeight.Medium)
        }
        Text(tr("done_today", "done today"), color = s.muted, fontSize = 11.sp)
        Spacer(Modifier.weight(1f))
        Row(Modifier.fillMaxWidth()) {
            listOf(
                "12" to tr("label_week", "Week"),
                "🔥5" to tr("label_best", "Best"),
            ).forEachIndexed { index, (value, label) ->
                if (index > 0) Spacer(Modifier.width(8.dp))
                Column(
                    Modifier.weight(1f).clip(RoundedCornerShape(12.dp))
                        .background(s.cell)
                        .padding(horizontal = 10.dp, vertical = 7.dp),
                ) {
                    Text(value, color = s.content, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text(
                        label.uppercase(), color = s.muted, fontSize = 9.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
            }
        }
    }

    @Composable
    private fun LivePreview(
        style: WidgetStyle,
        layout: Int,
        habitId: String?,
        allColor: Int,
    ) {
        val data = remember(habitId, allColor) {
            HabitCardData.load(this, habitId, if (habitId == null) allColor else null)
        }
        if (data == null) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(tr("open_to_sync", "Open Streak to sync"), color = style.muted, fontSize = 13.sp)
            }
            return
        }

        val density = resources.displayMetrics.density
        val tileDp = 36f
        val tilePx = (tileDp * density).toInt()
        val classic = layout == HeatmapConfig.LAYOUT_CLASSIC

        Column(Modifier.fillMaxSize()) {
            if (classic) {
                Text(
                    data.name, color = style.content, fontSize = 15.sp,
                    fontWeight = FontWeight.Bold, maxLines = 1,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center,
                )
            } else {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    BitmapImage(
                        remember(data.id, tilePx) {
                            CardBitmaps.tile(
                                tilePx,
                                CardBitmaps.withAlpha(data.color, 0.20f),
                                data.iconPath,
                                if (data.iconTintable) style.content.toArgb() else null,
                            )
                        },
                        tileDp.dp,
                    )
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text(data.name, color = style.content, fontSize = 15.sp,
                            fontWeight = FontWeight.Bold, maxLines = 1)
                        if (data.description.isNotEmpty()) {
                            Text(data.description, color = style.content.copy(alpha = 0.72f),
                                fontSize = 11.sp, maxLines = 1)
                        }
                    }
                    if (data.id != null) {
                        Spacer(Modifier.width(8.dp))
                        BitmapImage(
                            remember(data.id, data.doneToday, tilePx) {
                                CardBitmaps.check(
                                    tilePx,
                                    if (data.doneToday) data.color
                                    else CardBitmaps.withAlpha(data.color, 0.20f),
                                    if (data.doneToday) android.graphics.Color.WHITE else data.color,
                                )
                            },
                            tileDp.dp,
                        )
                    }
                }
            }
            Spacer(Modifier.height(10.dp))
            var gridSize by remember { mutableStateOf(IntSize.Zero) }
            Box(
                Modifier.fillMaxWidth().weight(1f)
                    .onSizeChanged { gridSize = it },
            ) {
                if (gridSize.width > 0 && gridSize.height > 0) {
                    val grid = remember(gridSize, data.id, classic, data.levels.size) {
                        CardBitmaps.grid(
                            gridSize.width, gridSize.height, data.levels, data.color,
                            if (classic) style.cell.toArgb() else null,
                        )
                    }
                    if (grid != null) {
                        Image(
                            grid.asImageBitmap(), null,
                            Modifier.fillMaxSize(),
                            contentScale = ContentScale.Fit,
                        )
                    }
                }
            }
        }
    }

    @Composable
    private fun BitmapImage(bitmap: android.graphics.Bitmap?, size: androidx.compose.ui.unit.Dp) {
        if (bitmap == null) {
            Spacer(Modifier.size(size))
            return
        }
        Image(bitmap.asImageBitmap(), null, Modifier.size(size))
    }

    @Composable
    private fun Dot(color: Color, size: androidx.compose.ui.unit.Dp, radius: androidx.compose.ui.unit.Dp) =
        Box(Modifier.size(size).clip(RoundedCornerShape(radius)).background(color))

    private fun label(value: String) = value.substringBefore("{").trim()

    @Composable
    private fun Label(text: String) =
        Text(text, color = mutedColor, fontSize = 13.sp, fontWeight = FontWeight.Medium)

    @Composable
    private fun ThemedSlider(value: Float, range: ClosedFloatingPointRange<Float>, onChange: (Float) -> Unit) =
        Slider(
            value = value, onValueChange = onChange, valueRange = range,
            colors = SliderDefaults.colors(
                thumbColor = brand, activeTrackColor = brand, inactiveTrackColor = cardColor,
            ),
        )

    @Composable
    private fun FilledButton(
        text: String, color: Color, height: androidx.compose.ui.unit.Dp = 48.dp,
        bold: Boolean = false, onClick: () -> Unit,
    ) = Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().height(height),
        shape = RoundedCornerShape(14.dp),
        colors = ButtonDefaults.buttonColors(containerColor = color),
    ) {
        Text(text, color = Color.White, fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium)
    }

    @Composable
    private fun Chip(label: String, on: Boolean, onClick: () -> Unit) = Box(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (on) brand.copy(alpha = 0.22f) else cardColor)
            .then(if (on) Modifier.border(1.5.dp, brand, RoundedCornerShape(10.dp)) else Modifier)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
    ) {
        Text(label, color = if (on) Color.White else mutedColor, fontWeight = FontWeight.Bold)
    }

    @Composable
    private fun HsvPicker(rgb: Int, onChange: (Int) -> Unit) {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(0xFF000000.toInt() or (rgb and 0x00FFFFFF), hsv)
        var h by remember { mutableStateOf(hsv[0]) }
        var s by remember { mutableStateOf(hsv[1].coerceAtLeast(0.05f)) }
        var v by remember { mutableStateOf(hsv[2].coerceAtLeast(0.05f)) }
        fun emit() = onChange(android.graphics.Color.HSVToColor(floatArrayOf(h, s, v)) and 0x00FFFFFF)
        Label(tr("cfg_hue", "Hue"))
        ThemedSlider(h, 0f..360f) { h = it; emit() }
        Label(tr("cfg_saturation", "Saturation"))
        ThemedSlider(s, 0f..1f) { s = it; emit() }
        Label(tr("cfg_brightness", "Brightness"))
        ThemedSlider(v, 0f..1f) { v = it; emit() }
    }

    @Composable
    private fun Swatches(selected: Int, custom: Boolean, onPick: (Int) -> Unit) {
        val rgbSel = selected and 0x00FFFFFF
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            swatches.chunked(7).forEach { row ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    row.forEach { c ->
                        val chosen = !custom && (c and 0x00FFFFFF) == rgbSel
                        Box(
                            Modifier.weight(1f).aspectRatio(1f).clip(CircleShape)
                                .background(Color(0xFF000000.toInt() or c))
                                .border(
                                    if (chosen) 3.dp else 1.dp,
                                    if (chosen) Color.White else Color(0x33FFFFFF), CircleShape,
                                )
                                .clickable { onPick(c) },
                        )
                    }
                    repeat(7 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }

    @Composable
    private fun HabitRow(option: HabitOption, selected: Boolean, onClick: () -> Unit) = Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (selected) brand.copy(alpha = 0.22f) else cardColor)
            .then(if (selected) Modifier.border(1.5.dp, brand, RoundedCornerShape(14.dp)) else Modifier)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(14.dp).clip(CircleShape).background(option.color))
        Spacer(Modifier.width(14.dp))
        Text(option.name, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Medium)
    }
}
