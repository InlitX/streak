import SwiftUI
import WidgetKit

struct HabitGridWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HabitWidgetProvider", provider: StreakProvider()) { entry in
      HabitGridView(payload: entry.payload)
    }
    .configurationDisplayName("Habits")
    .description("Your week, habit by habit")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct HabitGridView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  let payload: Payload?

  private static let labelWidth: CGFloat = 104
  private static let rateBar: CGFloat = 44

  private var rows: Int { family == .systemLarge ? 9 : 3 }

  var body: some View {
    let style = WidgetStyle.of(scheme)
    WidgetSurface(style) {
      VStack(alignment: .leading, spacing: 0) {
        if let payload, !payload.habits.isEmpty {
          header(payload, style)
          ForEach(payload.habits.prefix(rows), id: \.id) { habit in
            HabitRow(habit: habit, days: payload.days, style: style)
          }
          Spacer(minLength: 0)
        } else if payload != nil {
          EmptyMessage(
            text: WidgetStrings.get("no_habits", "No habits yet\nTap to open Streak"), style: style)
        } else {
          EmptyMessage(
            text: WidgetStrings.get("no_data", "No data yet\nOpen Streak to sync"), style: style)
        }
      }
      .widgetURL(Links.app)
    }
  }

  private func header(_ payload: Payload, _ style: WidgetStyle) -> some View {
    HStack(spacing: 8) {
      HStack {
        completionRate(payload.summary, style)
        Spacer(minLength: 0)
      }
      .frame(width: HabitGridView.labelWidth)
      HStack(spacing: 0) {
        ForEach(payload.days, id: \.key) { day in
          Text(day.label)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(day.isToday ? WidgetStyle.brand : style.muted)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private func completionRate(_ summary: WidgetSummary, _ style: WidgetStyle) -> some View {
    if summary.total > 0 {
      let ratio = min(1, max(0, Double(summary.doneToday) / Double(summary.total)))
      HStack(spacing: 6) {
        Text("\(Int(ratio * 100))%")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(style.content)
          .lineLimit(1)
        ZStack(alignment: .leading) {
          Capsule().fill(style.cell)
          if ratio > 0 {
            Capsule().fill(WidgetStyle.brand)
              .frame(width: max(4, HabitGridView.rateBar * ratio))
          }
        }
        .frame(width: HabitGridView.rateBar, height: 4)
      }
    }
  }
}

struct HabitRow: View {
  let habit: WidgetHabit
  let days: [WidgetDay]
  let style: WidgetStyle

  var body: some View {
    HStack(spacing: 8) {
      HStack(spacing: 0) {
        Text(habit.name)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(style.content)
          .lineLimit(1)
        Spacer(minLength: 0)
        StreakBadge(streak: habit.streak, color: habit.color, style: style)
      }
      .frame(width: 104)
      HStack(spacing: 0) {
        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
          cell(index, day)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.vertical, 2)
  }

  @ViewBuilder
  private func cell(_ index: Int, _ day: WidgetDay) -> some View {
    let mark = DayMark(habit: habit, index: index)
      .frame(width: 24, height: 24)
    if habit.opensApp {
      Link(destination: habit.focusOnly ? Links.focus(habit.id) : Links.habit(habit.id)) { mark }
    } else {
      Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: day.key)) { mark }
        .buttonStyle(.plain)
    }
  }
}

struct DayMark: View {
  let habit: WidgetHabit
  let index: Int

  private var done: Bool { habit.completions.count > index && habit.completions[index] }
  private var count: Double { habit.counts.count > index ? habit.counts[index] : 0 }

  var body: some View {
    if habit.kind == WidgetHabit.negative {
      if count > 0 {
        Text("✕")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(.primary)
      } else {
        CompletionIndicator(done: done, color: habit.color)
      }
    } else if habit.quantified {
      ValueIndicator(count: count, ratio: count / habit.perDayTarget, color: habit.color)
    } else {
      CompletionIndicator(done: done, color: habit.color)
    }
  }
}

struct ValueIndicator: View {
  let count: Double
  let ratio: Double
  let color: Color

  var body: some View {
    if count <= 0 {
      CompletionIndicator(done: false, color: color)
    } else {
      let clamped = min(1, max(0, ratio))
      let label = Amounts.compact(count)
      Text(label)
        .font(.system(size: label.count > 3 ? 7 : (label.count > 2 ? 8 : 10), weight: .bold))
        .foregroundStyle(clamped >= 0.6 ? Color.white : color)
        .lineLimit(1)
        .frame(width: 20, height: 20)
        .background(RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.35 + 0.65 * clamped)))
    }
  }
}
