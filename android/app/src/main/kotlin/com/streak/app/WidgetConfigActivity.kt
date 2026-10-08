package com.streak.app

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
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.File

private val screenBg = Color(0xFF0E0E12)
private val cardColor = Color(0xFF19191F)
private val fieldColor = Color(0xFF26262E)
private val barColor = Color(0xFF131318)
private val lineColor = Color(0x0FFFFFFF)
private val brand = Color(0xFF7C5CFC)
private val ink = Color(0xFFF5F5F7)
private val mutedColor = Color(0xFF9A9AA6)

private val swatches = listOf(
    0x101014, 0x1B1B22, 0x3A3A44, 0xF2F2F5, 0x7C5CFC, 0x2196F3, 0x00BCD4,
    0x009688, 0x4CAF50, 0xFFC107, 0xFF9800, 0xF44336, 0xE91E63, 0x607D8B,
)

private enum class WType { HABIT, TODAY, STATS, HEATMAP, TODOS }

private data class HabitOption(val id: String?, val name: String, val color: Color)

private const val BRAND_FALLBACK = 0xFF7C3AED.toInt()

class WidgetConfigActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var providerClass = ""
    private var type = WType.HABIT

    private val rounded by lazy {
        val weights = listOf(
            "Regular" to FontWeight.Normal,
            "Medium" to FontWeight.Medium,
            "SemiBold" to FontWeight.SemiBold,
            "Bold" to FontWeight.Bold,
            "ExtraBold" to FontWeight.ExtraBold,
        )
        try {
            FontFamily(weights.map { (name, weight) -> Font("flutter_assets/fonts/GoogleSansRounded-$name.ttf", assets, weight) })
        } catch (e: Exception) {
            FontFamily.Default
        }
    }

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

        providerClass = providerOf(appWidgetId)
        type = typeOf(providerClass)

        originalImage = WidgetConfig.image(this, appWidgetId)
        imageState.value = originalImage
        bgModeState.value = WidgetConfig.bgMode(this, appWidgetId)

        setContent {
            Screen(
                habits = if (type == WType.TODOS) emptyList() else loadOptions(),
                initialBg = WidgetConfig.bg(this, appWidgetId),
                initialOpacity = WidgetConfig.opacity(this, appWidgetId),
                initialBorder = WidgetConfig.border(this, appWidgetId),
                initialBorderWidth = WidgetConfig.borderWidth(this, appWidgetId),
                initialHabit = HeatmapConfig.habitOf(this, appWidgetId),
                initialAllColor = HeatmapConfig.colorOf(this, appWidgetId),
                initialLayout = HeatmapConfig.layoutOf(this, appWidgetId),
                initialFollowSystem = WidgetConfig.followSystem(this, appWidgetId),
                initialBgLight = WidgetConfig.bgLight(this, appWidgetId),
                initialTodosAll = WidgetConfig.todosAll(this, appWidgetId),
                initialArt = WidgetConfig.art(this, appWidgetId),
                initialSpan = WidgetConfig.span(this, appWidgetId),
                initialChosen = WidgetConfig.habits(this, appWidgetId),
                isEdit = WidgetConfig.exists(this, appWidgetId),
            )
        }
    }

    private fun providerOf(id: Int): String {
        val manager = AppWidgetManager.getInstance(this)
        val declared = manager.getAppWidgetInfo(id)?.provider?.className
        if (!declared.isNullOrEmpty()) return declared
        val providers = listOf(
            TodosWidgetProvider::class.java,
            TodayWidgetProvider::class.java,
            StatsWidgetProvider::class.java,
            HeatmapWidgetProvider::class.java,
            HabitWidgetProvider::class.java,
        )
        for (provider in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(this, provider))
            if (ids.any { it == id }) return provider.name
        }
        return ""
    }

    private fun typeOf(name: String) = when {
        name.contains("Todos") -> WType.TODOS
        name.contains("Today") -> WType.TODAY
        name.contains("Stats") -> WType.STATS
        name.contains("Heatmap") -> WType.HEATMAP
        else -> WType.HABIT
    }

    private fun tr(key: String, fallback: String) = WidgetText.get(this, key, fallback)

    private fun save(
        bg: Int, opacity: Int, border: Boolean, borderWidth: Int,
        habitId: String?, allColor: Int, layout: Int,
        followSystem: Boolean, bgLight: Int, todosAll: Boolean,
        chosen: Set<String>, art: Boolean, span: Int,
    ) {
        val image = if (bgModeState.value == 1) imageState.value else null
        WidgetConfig.set(
            this, appWidgetId, bg, opacity, border, borderWidth,
            if (image != null) 1 else 0, image, followSystem, bgLight,
        )
        if (image != originalImage) WidgetConfig.deleteImage(this, originalImage)
        if (type == WType.TODOS) WidgetConfig.setTodosAll(this, appWidgetId, todosAll)
        if (type == WType.STATS || type == WType.TODOS) WidgetConfig.setArt(this, appWidgetId, art)
        if (type == WType.HABIT) WidgetConfig.setSpan(this, appWidgetId, span)
        if (filters) WidgetConfig.setHabits(this, appWidgetId, chosen)
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
                if (providerClass.isNotEmpty()) GlanceWidgets.refresh(ctx, widgetFor(type), glanceId)
            } catch (_: Exception) {
            }
            finish()
        }
    }

    private val filters get() = type == WType.HABIT || type == WType.TODAY || type == WType.STATS

    private fun widgetFor(t: WType): GlanceAppWidget = when (t) {
        WType.TODOS -> TodosWidget()
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
            all + (0 until habits.length()).mapNotNull { i ->
                habits.optJSONObject(i)?.let {
                    HabitOption(
                        it.optString("id"),
                        it.optString("name"),
                        Color(it.optInt("color", BRAND_FALLBACK)),
                    )
                }
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
        initialTodosAll: Boolean,
        initialArt: Boolean,
        initialSpan: Int,
        initialChosen: Set<String>,
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
        var todosAll by remember { mutableStateOf(initialTodosAll) }
        var art by remember { mutableStateOf(initialArt) }
        var span by remember { mutableStateOf(initialSpan) }
        var chosen by remember { mutableStateOf(initialChosen) }
        val mode by bgModeState
        val image by imageState

        val night = WidgetConfig.isNight(this)
        val shown = if (followSystem && !night) bgLight else bg
        val style = if (mode == 1 && image != null) {
            WidgetStyle.image(image!!, opacity, border, borderWidth)
        } else {
            WidgetStyle.from(shown, opacity, border, borderWidth)
        }

        val hasArt = type == WType.STATS || type == WType.TODOS
        val hasPicker = filters && habits.size > 1
        val hasContent = type == WType.HEATMAP || type == WType.TODOS || type == WType.HABIT || hasArt || hasPicker

        CompositionLocalProvider(LocalTextStyle provides TextStyle(fontFamily = rounded, color = ink)) {
            Column(modifier = Modifier.fillMaxSize().background(screenBg)) {
                Column(modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 22.dp)) {
                    Text(tr("cfg_title", "Customize widget"), fontSize = 24.sp, fontWeight = FontWeight.ExtraBold)
                    Spacer(Modifier.height(16.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(28.dp))
                            .background(Brush.linearGradient(listOf(Color(0xFF2B2640), Color(0xFF16161D))))
                            .padding(18.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Preview(style, image.takeIf { mode == 1 }, layout, habitId, allColor, art, span)
                    }
                }
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 20.dp),
                ) {
                    Spacer(Modifier.height(8.dp))
                    if (hasContent) {
                        Group(tr("cfg_content", "Content")) {
                            if (type == WType.HEATMAP) {
                                Inset {
                                    Segmented(
                                        left = tr("cfg_style_classic", "Classic"),
                                        right = tr("cfg_style_card", "Card"),
                                        selected = if (layout == HeatmapConfig.LAYOUT_CARD) 1 else 0,
                                        onLeft = { layout = HeatmapConfig.LAYOUT_CLASSIC },
                                        onRight = { layout = HeatmapConfig.LAYOUT_CARD },
                                    )
                                }
                            }
                            if (type == WType.HABIT) {
                                Inset {
                                    Label(tr("cfg_days", "Days shown"))
                                    Spacer(Modifier.height(12.dp))
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Chip(tr("this_week", "This week"), span == 7) { span = 7 }
                                        Chip("8", span == 8) { span = 8 }
                                        Chip("9", span == 9) { span = 9 }
                                    }
                                }
                            }
                            if (type == WType.TODOS) {
                                ToggleRow(
                                    tr("cfg_todos_all", "Show every task"),
                                    tr("cfg_todos_hint", "Off: only today, late and undated tasks"),
                                    todosAll,
                                ) { todosAll = it }
                            }
                            if (hasArt) {
                                if (type == WType.TODOS) Line()
                                ToggleRow(tr("cfg_show_art", "Show illustration"), null, art) { art = it }
                            }
                        }
                        if (type == WType.HEATMAP && habits.isNotEmpty()) {
                            Group(tr("cfg_show_activity", "Show activity of")) {
                                habits.forEachIndexed { index, o ->
                                    if (index > 0) Line()
                                    HabitRow(o, o.id == habitId) { habitId = o.id }
                                }
                                if (habitId == null) {
                                    Line()
                                    Inset {
                                        Label(tr("cfg_dot_color", "Dot color"))
                                        Spacer(Modifier.height(12.dp))
                                        Swatches(allColor, custom = false) { allColor = 0xFF000000.toInt() or it }
                                    }
                                }
                            }
                        }
                        if (hasPicker) {
                            Group(
                                tr("cfg_show_habits", "Habits to show"),
                                if (type == WType.STATS) {
                                    tr("cfg_show_habits_hint", "With one habit, the summary shows its streak.")
                                } else {
                                    null
                                },
                            ) {
                                habits.forEachIndexed { index, o ->
                                    if (index > 0) Line()
                                    val id = o.id
                                    HabitRow(o, if (id == null) chosen.isEmpty() else id in chosen) {
                                        chosen = when {
                                            id == null -> emptySet()
                                            id in chosen -> chosen - id
                                            else -> chosen + id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Group(tr("cfg_background", "Background")) {
                        Inset {
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
                                SoftButton(
                                    if (image == null) tr("cfg_choose_image", "Choose image")
                                    else tr("cfg_change_image", "Change image"),
                                ) { pickImage.launch("image/*") }
                            } else {
                                if (followSystem) {
                                    Label(tr("cfg_dark_color", "Dark theme"))
                                    Spacer(Modifier.height(12.dp))
                                }
                                Swatches(bg, custom) { bg = it; custom = false }
                                Spacer(Modifier.height(14.dp))
                                Chip(tr("cfg_custom_color", "Custom color"), custom) { custom = !custom }
                                if (custom) {
                                    Spacer(Modifier.height(12.dp))
                                    HsvPicker(bg) { bg = it }
                                }
                                if (followSystem) {
                                    Spacer(Modifier.height(22.dp))
                                    Label(tr("cfg_light_color", "Light theme"))
                                    Spacer(Modifier.height(12.dp))
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
                        }
                        if (mode == 0) {
                            Line()
                            ToggleRow(tr("cfg_follow_system", "Follow system theme"), null, followSystem) {
                                followSystem = it
                            }
                        }
                        Line()
                        Inset {
                            SliderRow(label(tr("cfg_opacity", "Opacity")), "$opacity%", opacity.toFloat(), 0f..100f) {
                                opacity = it.toInt()
                            }
                        }
                    }

                    Group(tr("cfg_border", "Border")) {
                        ToggleRow(tr("cfg_border", "Border"), null, border) { border = it }
                        if (border) {
                            Line()
                            Inset {
                                SliderRow(
                                    label(tr("cfg_thickness", "Thickness")),
                                    "${borderWidth}dp",
                                    borderWidth.toFloat(),
                                    1f..8f,
                                ) { borderWidth = it.toInt() }
                            }
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                }

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(barColor)
                        .navigationBarsPadding()
                        .padding(start = 20.dp, end = 20.dp, top = 14.dp, bottom = 6.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(54.dp)
                            .clip(RoundedCornerShape(18.dp))
                            .background(brand)
                            .clickable {
                                save(
                                    bg, opacity, border, borderWidth, habitId, allColor, layout,
                                    followSystem, bgLight, todosAll, chosen, art, span,
                                )
                            },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            if (isEdit) tr("cfg_save", "Save") else tr("cfg_add", "Add widget"),
                            color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.ExtraBold,
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
                                art = true
                                span = 7
                                todosAll = false
                                chosen = emptySet()
                                bgModeState.value = 0
                                imageState.value = null
                            }
                            .padding(vertical = 12.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            tr("cfg_reset", "Reset to default"),
                            color = mutedColor, fontSize = 14.sp, fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
        }
    }

    @Composable
    private fun Group(title: String, hint: String? = null, content: @Composable ColumnScope.() -> Unit) {
        Spacer(Modifier.height(22.dp))
        Text(
            title,
            color = mutedColor,
            fontSize = 13.sp,
            fontWeight = FontWeight.ExtraBold,
            modifier = Modifier.padding(start = 6.dp, bottom = 10.dp),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(24.dp))
                .background(cardColor),
            content = content,
        )
        if (hint != null) {
            Text(
                hint,
                color = mutedColor,
                fontSize = 12.5.sp,
                modifier = Modifier.padding(start = 6.dp, end = 6.dp, top = 8.dp),
            )
        }
    }

    @Composable
    private fun Inset(content: @Composable ColumnScope.() -> Unit) =
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp), content = content)

    @Composable
    private fun Line() = Box(
        Modifier.padding(start = 16.dp).fillMaxWidth().height(1.dp).background(lineColor),
    )

    @Composable
    private fun ToggleRow(title: String, sub: String?, checked: Boolean, onChange: (Boolean) -> Unit) = Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onChange(!checked) }
            .padding(start = 16.dp, end = 12.dp, top = 12.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            if (sub != null) {
                Spacer(Modifier.height(2.dp))
                Text(sub, color = mutedColor, fontSize = 12.5.sp)
            }
        }
        Spacer(Modifier.width(12.dp))
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedTrackColor = brand,
                checkedThumbColor = Color.White,
                uncheckedTrackColor = fieldColor,
                uncheckedThumbColor = mutedColor,
                uncheckedBorderColor = Color.Transparent,
            ),
        )
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
            .clip(RoundedCornerShape(16.dp))
            .background(fieldColor)
            .padding(4.dp),
    ) {
        listOf(left to onLeft, right to onRight).forEachIndexed { index, (label, action) ->
            val on = selected == index
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (on) Color(0xFF3A3A46) else Color.Transparent)
                    .clickable(onClick = action)
                    .padding(vertical = 11.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label,
                    color = if (on) ink else mutedColor,
                    fontSize = 14.5.sp,
                    fontWeight = FontWeight.ExtraBold,
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
            Text(title, fontSize = 16.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Box(
                Modifier.clip(RoundedCornerShape(10.dp)).background(fieldColor)
                    .padding(horizontal = 10.dp, vertical = 4.dp),
            ) {
                Text(value, fontSize = 13.sp, fontWeight = FontWeight.ExtraBold)
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
        art: Boolean,
        span: Int,
    ) = Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        val frame = when (type) {
            WType.STATS -> Modifier.size(158.dp)
            WType.TODAY, WType.HABIT -> Modifier.fillMaxWidth().height(176.dp)
            else -> Modifier.fillMaxWidth().height(150.dp)
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
            if (type == WType.STATS && art) {
                Image(
                    painterResource(
                        if (style.content.luminance() < 0.5f) R.drawable.widget_streak_flame_light
                        else R.drawable.widget_streak_flame,
                    ),
                    null,
                    Modifier.matchParentSize(),
                )
            }
            when (type) {
                WType.HABIT -> WeekSample(style, span)
                WType.TODAY -> TodaySample(style)
                WType.STATS -> StatsSample(style, art)
                WType.HEATMAP -> Box(Modifier.padding(14.dp)) { LivePreview(style, layout, habitId, allColor) }
                WType.TODOS -> TodosSample(style, art)
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
        val data = remember(habitId, allColor, style.dark) {
            HabitCardData.load(this, habitId, if (habitId == null) allColor else null)?.tinted(style.dark)
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
                    fontWeight = FontWeight.ExtraBold, maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center,
                )
            } else {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    BitmapImage(
                        remember(data.id, data.color, tilePx) {
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
                        Text(
                            data.name, color = style.content, fontSize = 15.sp,
                            fontWeight = FontWeight.ExtraBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                        )
                        if (data.description.isNotEmpty()) {
                            Text(
                                data.description, color = style.content.copy(alpha = 0.72f),
                                fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                                maxLines = 1, overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                    if (data.id != null) {
                        Spacer(Modifier.width(8.dp))
                        BitmapImage(
                            remember(data.id, data.color, data.doneToday, tilePx) {
                                CardBitmaps.check(
                                    tilePx,
                                    if (data.doneToday) data.color
                                    else CardBitmaps.withAlpha(data.color, 0.20f),
                                    if (data.doneToday) CardBitmaps.inkOn(data.color) else data.color,
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
                    val grid = remember(gridSize, data.id, data.color, classic, data.levels.size, style.cell) {
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

    private fun label(value: String) = value.substringBefore("{").trim()

    @Composable
    private fun Label(text: String) =
        Text(text, color = mutedColor, fontSize = 13.sp, fontWeight = FontWeight.Bold)

    @Composable
    private fun ThemedSlider(value: Float, range: ClosedFloatingPointRange<Float>, onChange: (Float) -> Unit) =
        Slider(
            value = value, onValueChange = onChange, valueRange = range,
            colors = SliderDefaults.colors(
                thumbColor = Color.White, activeTrackColor = brand, inactiveTrackColor = fieldColor,
            ),
        )

    @Composable
    private fun SoftButton(text: String, onClick: () -> Unit) = Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(fieldColor)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, fontSize = 15.sp, fontWeight = FontWeight.ExtraBold)
    }

    @Composable
    private fun Chip(label: String, on: Boolean, onClick: () -> Unit) = Box(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (on) brand.copy(alpha = 0.22f) else fieldColor)
            .then(if (on) Modifier.border(1.5.dp, brand, RoundedCornerShape(12.dp)) else Modifier)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
    ) {
        Text(label, color = if (on) ink else mutedColor, fontSize = 14.sp, fontWeight = FontWeight.ExtraBold)
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
                                .then(if (chosen) Modifier.border(2.dp, ink, CircleShape) else Modifier)
                                .clickable { onPick(c) }
                                .padding(if (chosen) 4.dp else 0.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF000000.toInt() or c))
                                .border(1.dp, Color(0x1FFFFFFF), CircleShape),
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
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(12.dp).clip(CircleShape).background(Color(CardBitmaps.shown(option.color.toArgb(), true))))
        Spacer(Modifier.width(14.dp))
        Text(
            option.name, fontSize = 16.sp, fontWeight = FontWeight.Bold,
            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(12.dp))
        Tick(selected)
    }

    @Composable
    private fun Tick(on: Boolean) = Canvas(Modifier.size(24.dp)) {
        val r = size.minDimension / 2f
        if (on) {
            drawCircle(brand, r)
            val path = Path().apply {
                moveTo(size.width * 0.29f, size.height * 0.52f)
                lineTo(size.width * 0.44f, size.height * 0.67f)
                lineTo(size.width * 0.72f, size.height * 0.36f)
            }
            drawPath(path, Color.White, style = Stroke(width = 2.4.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
        } else {
            drawCircle(Color(0x40FFFFFF), r - 1.dp.toPx(), style = Stroke(width = 2.dp.toPx()))
        }
    }
}
