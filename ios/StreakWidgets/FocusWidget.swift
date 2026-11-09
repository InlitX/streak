import SwiftUI
import WidgetKit

struct FocusWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "FocusBoardWidgetProvider", provider: StreakProvider()) { entry in
      FocusView(payload: entry.payload)
    }
    .configurationDisplayName("Focus")
    .description("Focus time today, this week and your streak")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct FocusTotals {
  let today: Int
  let week: Int
  let month: Int
  let streak: Int
  let days: [Int]

  static func load() -> FocusTotals {
    let focus = Shared.object(Shared.habitsKey)?["focus"] as? [String: Any]
    let raw = (focus?[""] as? [Any] ?? []).map { ($0 as? NSNumber)?.intValue ?? 0 }
    let values = raw + Array(repeating: 0, count: max(0, 11 - raw.count))
    return FocusTotals(
      today: values[0], week: values[1], month: values[2], streak: values[3],
      days: Array(values[4..<11]))
  }

  static func duration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let hours = minutes / 60
    let rest = minutes % 60
    if hours == 0 { return "\(rest)m" }
    if rest == 0 { return "\(hours)h" }
    return "\(hours)h \(rest)m"
  }
}

struct FocusView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  let payload: Payload?

  private var tiny: Bool { family == .systemSmall }

  var body: some View {
    let style = WidgetStyle.of(scheme)
    let totals = FocusTotals.load()
    WidgetSurface(style) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 0) {
          Text(FocusTotals.duration(totals.today))
            .font(.system(size: tiny ? 26 : 32, weight: .bold))
            .foregroundStyle(style.content)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
          Text(WidgetStrings.get("focus_today", "Focus today"))
            .font(.system(size: tiny ? 11 : 12, weight: .semibold))
            .foregroundStyle(style.content)
            .lineLimit(1)
          Spacer(minLength: 0)
          line(WidgetStrings.get("label_week", "Week"), FocusTotals.duration(totals.week), style)
          line(WidgetStrings.get("label_month", "Month"), FocusTotals.duration(totals.month), style)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if !tiny {
          VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
              Text(Amounts.compact(totals.streak))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(style.content)
              Text(WidgetStrings.get("streak_days", "Streak days"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(style.muted)
                .lineLimit(1)
              Spacer(minLength: 0)
              Link(destination: Links.page("focusStart")) {
                Image(systemName: "play.circle.fill")
                  .font(.system(size: 26))
                  .foregroundStyle(style.content)
              }
            }
            bars(totals.days, style)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .widgetURL(Links.page("focusPage"))
    }
  }

  private func line(_ label: String, _ value: String, _ style: WidgetStyle) -> some View {
    Text("\(label)  \(value)")
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(style.muted)
      .lineLimit(1)
  }

  private func bars(_ days: [Int], _ style: WidgetStyle) -> some View {
    let top = max(1, days.max() ?? 1)
    let labels = payload?.days.map { $0.label } ?? []
    return HStack(alignment: .bottom, spacing: 5) {
      ForEach(0..<days.count, id: \.self) { i in
        VStack(spacing: 3) {
          Spacer(minLength: 0)
          RoundedRectangle(cornerRadius: 3)
            .fill(days[i] > 0 ? WidgetStyle.brand : style.cell)
            .frame(height: max(4, CGFloat(days[i]) / CGFloat(top) * 56))
          Text(i < labels.count ? String(labels[i].prefix(1)).uppercased() : "")
            .font(.system(size: 9, weight: i == days.count - 1 ? .bold : .medium))
            .foregroundStyle(i == days.count - 1 ? style.content : style.muted)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(maxHeight: .infinity)
  }
}
