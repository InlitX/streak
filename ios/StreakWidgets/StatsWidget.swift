import SwiftUI
import WidgetKit

struct StatsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "StatsWidgetProvider", provider: StreakProvider()) { entry in
      StatsView(payload: entry.payload)
    }
    .configurationDisplayName("Stats")
    .description("Done today, this week and your best streak")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct StatsView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  let payload: Payload?

  private var tiny: Bool { family == .systemSmall }

  var body: some View {
    let style = WidgetStyle.of(scheme)
    let summary = payload?.summary
    WidgetSurface(style) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 5) {
          Text("🔥").font(.system(size: tiny ? 10 : 12))
          Text("S T R E A K")
            .font(.system(size: tiny ? 9 : 10, weight: .bold))
            .foregroundStyle(style.muted)
        }
        Spacer().frame(height: tiny ? 4 : 8)
        HStack(alignment: .lastTextBaseline, spacing: 5) {
          Text(Amounts.compact(summary?.doneToday ?? 0))
            .font(.system(size: tiny ? 26 : 32, weight: .bold))
            .foregroundStyle(style.content)
          Text("/ \(Amounts.compact(summary?.total ?? 0))")
            .font(.system(size: tiny ? 13 : 16, weight: .medium))
            .foregroundStyle(style.muted)
        }
        if !tiny {
          Text(WidgetStrings.get("done_today", "done today"))
            .font(.system(size: 11))
            .foregroundStyle(style.muted)
        }
        Spacer(minLength: 0)
        HStack(spacing: 7) {
          tile(
            value: Amounts.compact(summary?.weekDone ?? 0),
            label: WidgetStrings.get("label_week", "Week"),
            style: style)
          tile(
            value: "🔥\(Amounts.compact(summary?.bestStreak ?? 0))",
            label: WidgetStrings.get("label_best", "Best"),
            style: style)
        }
      }
      .widgetURL(Links.page("stats"))
    }
  }

  private func tile(value: String, label: String, style: WidgetStyle) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(value)
        .font(.system(size: tiny ? 13 : 16, weight: .bold))
        .foregroundStyle(style.content)
        .lineLimit(1)
      Text(label.uppercased())
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(style.muted)
        .lineLimit(1)
    }
    .padding(.horizontal, 9)
    .padding(.vertical, tiny ? 5 : 7)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12).fill(style.cell))
  }
}
