import SwiftUI
import WidgetKit

struct HeatmapEntry: TimelineEntry {
  let date: Date
  let payload: Payload?
  let habitId: String?
  let style: HeatmapStyle
}

struct HeatmapProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> HeatmapEntry {
    HeatmapEntry(date: Date(), payload: nil, habitId: nil, style: .classic)
  }

  func snapshot(for configuration: HeatmapConfigurationIntent, in context: Context) async -> HeatmapEntry {
    HeatmapEntry(
      date: Date(), payload: Payload.load(), habitId: configuration.habit?.id, style: configuration.style)
  }

  func timeline(for configuration: HeatmapConfigurationIntent, in context: Context) async -> Timeline<HeatmapEntry> {
    let dates = Timelines.dates()
    let entries = dates.map {
      HeatmapEntry(
        date: $0, payload: Payload.load(at: $0), habitId: configuration.habit?.id,
        style: configuration.style)
    }
    return Timeline(entries: entries, policy: .after(dates[1]))
  }
}

struct HeatmapWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "HeatmapWidgetProvider", intent: HeatmapConfigurationIntent.self, provider: HeatmapProvider()
    ) { entry in
      HeatmapView(entry: entry)
    }
    .configurationDisplayName("Heatmap")
    .description("A year of one habit, or of all of them")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct HeatmapCard {
  static let allColor = Color(argb: 0xFF7C5CFC)

  let habit: WidgetHabit?
  let name: String
  let description: String
  let color: Color
  let icon: UIImage?
  let tintable: Bool
  let levels: [Int]

  init?(payload: Payload?, habitId: String?) {
    guard let payload else { return nil }
    if let habitId {
      guard let habit = payload.habits.first(where: { $0.id == habitId }) else { return nil }
      self.habit = habit
      name = habit.name
      description = habit.description
      color = habit.color
      icon = habit.icon
      tintable = habit.iconTintable
      levels = habit.heatmap
    } else {
      habit = nil
      name = WidgetStrings.get("activity", "Activity")
      description = ""
      color = HeatmapCard.allColor
      icon = payload.fallbackIcon
      tintable = true
      levels = payload.heatmap
    }
    if levels.count < HeatmapGrid.rows { return nil }
  }
}

struct HeatmapView: View {
  @Environment(\.colorScheme) private var scheme

  let entry: HeatmapEntry

  private static let gap: CGFloat = 10
  private static let tileMax: CGFloat = 42
  private static let tileMin: CGFloat = 28
  private static let classicTitle: CGFloat = 24
  private static let tightWidth: CGFloat = 180

  var body: some View {
    let style = WidgetStyle.of(scheme)
    let card = HeatmapCard(payload: entry.payload, habitId: entry.habitId)
    WidgetSurface(style) {
      if let card {
        GeometryReader { geometry in
          content(card, style, geometry.size)
        }
        .widgetURL(card.habit.map { Links.habit($0.id) } ?? Links.app)
      } else {
        EmptyMessage(text: WidgetStrings.get("open_to_sync", "Open Streak to sync"), style: style)
          .widgetURL(Links.app)
      }
    }
  }

  @ViewBuilder
  private func content(_ card: HeatmapCard, _ style: WidgetStyle, _ size: CGSize) -> some View {
    let classic = entry.style == .classic
    let tight = !classic && size.width < HeatmapView.tightWidth
    VStack(alignment: .leading, spacing: HeatmapView.gap) {
      if classic {
        Text(card.name)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(style.content)
          .lineLimit(1)
          .frame(height: HeatmapView.classicTitle, alignment: .leading)
      } else {
        let tile = min(HeatmapView.tileMax, max(HeatmapView.tileMin, size.height * 0.32))
        header(card, style, tile: tile, tight: tight)
      }
      HeatmapGrid(levels: card.levels, accent: card.color, empty: classic ? style.cell : nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func header(_ card: HeatmapCard, _ style: WidgetStyle, tile: CGFloat, tight: Bool) -> some View {
    let done = card.habit?.doneToday ?? false
    let filled = tight && done
    return HStack(spacing: 10) {
      tileButton(card, tile: tile, tight: tight, filled: filled, style: style)
      VStack(alignment: .leading, spacing: 1) {
        Text(card.name)
          .font(.system(size: tile >= 38 ? 17 : 15, weight: .semibold))
          .foregroundStyle(style.content)
          .lineLimit(1)
        if !tight, !card.description.isEmpty, tile >= 34 {
          Text(card.description)
            .font(.system(size: 12))
            .foregroundStyle(style.content.opacity(0.72))
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
      if !tight, let habit = card.habit {
        checkButton(habit, tile: tile, done: done)
      }
    }
    .frame(height: tile)
  }

  @ViewBuilder
  private func tileButton(_ card: HeatmapCard, tile: CGFloat, tight: Bool, filled: Bool, style: WidgetStyle) -> some View {
    let face = ZStack {
      RoundedRectangle(cornerRadius: tile * 12 / 42)
        .fill(filled ? card.color : card.color.opacity(0.2))
      glyph(card, tint: !card.tintable ? nil : (filled ? .white : (tight ? card.color : style.content)), size: tile * 0.55)
    }
    .frame(width: tile, height: tile)
    if tight, let habit = card.habit, !habit.opensApp {
      Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: entry.payload?.todayKey ?? "")) { face }
        .buttonStyle(.plain)
    } else if let habit = card.habit {
      Link(destination: habit.focusOnly ? Links.focus(habit.id) : Links.habit(habit.id)) { face }
    } else {
      face
    }
  }

  @ViewBuilder
  private func glyph(_ card: HeatmapCard, tint: Color?, size: CGFloat) -> some View {
    if let icon = card.icon {
      Image(uiImage: icon)
        .renderingMode(card.tintable ? .template : .original)
        .resizable()
        .scaledToFit()
        .foregroundStyle(tint ?? card.color)
        .frame(width: size, height: size)
    } else {
      Image(systemName: "sparkles")
        .font(.system(size: size * 0.8))
        .foregroundStyle(tint ?? card.color)
    }
  }

  @ViewBuilder
  private func checkButton(_ habit: WidgetHabit, tile: CGFloat, done: Bool) -> some View {
    let face = ZStack {
      RoundedRectangle(cornerRadius: tile * 12 / 42)
        .fill(done ? habit.color : habit.color.opacity(0.2))
      Image(systemName: "checkmark")
        .font(.system(size: tile * 0.4, weight: .bold))
        .foregroundStyle(done ? .white : habit.color)
    }
    .frame(width: tile, height: tile)
    if habit.opensApp {
      Link(destination: habit.focusOnly ? Links.focus(habit.id) : Links.habit(habit.id)) { face }
    } else {
      Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: entry.payload?.todayKey ?? "")) { face }
        .buttonStyle(.plain)
    }
  }
}

struct HeatmapGrid: View {
  static let rows = 7

  let levels: [Int]
  let accent: Color
  let empty: Color?

  var body: some View {
    Canvas { context, size in
      let rows = CGFloat(HeatmapGrid.rows)
      let pitch = size.height / rows
      let cell = pitch * 11 / 13
      let gap = pitch - cell
      let fits = max(1, Int((size.width + gap) / pitch))
      let weeks = min(fits, levels.count / HeatmapGrid.rows)
      guard weeks > 0 else { return }
      let start = (levels.count / HeatmapGrid.rows - weeks) * HeatmapGrid.rows
      let step = weeks > 1 ? (size.width - cell) / CGFloat(weeks - 1) : 0
      let radius = cell * 3 / 11
      for column in 0..<weeks {
        for row in 0..<HeatmapGrid.rows {
          let level = levels[start + column * HeatmapGrid.rows + row]
          let rect = CGRect(x: CGFloat(column) * step, y: CGFloat(row) * pitch, width: cell, height: cell)
          context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color(for: level)))
        }
      }
    }
  }

  private func color(for level: Int) -> Color {
    if level <= 0, let empty {
      return level == -1 ? empty.opacity(0.35) : empty
    }
    let alpha: Double
    switch level {
    case -1: alpha = 0.08
    case 1: alpha = 0.40
    case 2: alpha = 0.60
    case 3: alpha = 0.80
    case 4: alpha = 1
    default: alpha = 0.20
    }
    return accent.opacity(alpha)
  }
}
