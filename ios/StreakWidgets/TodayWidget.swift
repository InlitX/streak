import SwiftUI
import WidgetKit

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayWidgetProvider", provider: StreakProvider()) { entry in
      TodayView(payload: entry.payload)
    }
    .configurationDisplayName("Today")
    .description("Tick off today's habits")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct TodayView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  let payload: Payload?

  private var rows: Int { family == .systemLarge ? 8 : 3 }

  var body: some View {
    let style = WidgetStyle.of(scheme)
    let summary = payload?.summary
    WidgetSurface(style) {
      VStack(alignment: .leading, spacing: 0) {
        Text(
          WidgetStrings.format(
            "today_progress", "Today  {done}/{total}",
            ["{done}": String(summary?.doneToday ?? 0), "{total}": String(summary?.total ?? 0)])
        )
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(style.content)
        .padding(.bottom, 6)
        if let payload, !payload.habits.isEmpty {
          ForEach(payload.habits.prefix(rows), id: \.id) { habit in
            TodayRow(habit: habit, todayKey: payload.todayKey, style: style)
          }
          Spacer(minLength: 0)
        } else {
          Text(WidgetStrings.get("open_to_sync", "Open Streak to sync"))
            .font(.system(size: 13))
            .foregroundStyle(style.muted)
          Spacer(minLength: 0)
        }
      }
      .widgetURL(Links.app)
    }
  }
}

struct TodayRow: View {
  let habit: WidgetHabit
  let todayKey: String
  let style: WidgetStyle

  var body: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 1) {
        HStack(spacing: 0) {
          Text(habit.name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(style.content)
            .lineLimit(1)
          Spacer(minLength: 0)
          StreakBadge(streak: habit.streak, color: habit.color, style: style)
        }
        if habit.quantified {
          Text("\(Amounts.format(habit.todayCount))/\(Amounts.format(habit.perDayTarget))")
            .font(.system(size: 11))
            .foregroundStyle(style.muted)
        }
      }
      box
    }
    .padding(.vertical, 3)
  }

  @ViewBuilder
  private var box: some View {
    let face = TodayBox(habit: habit, style: style)
    if habit.opensApp {
      Link(destination: habit.focusOnly ? Links.focus(habit.id) : Links.habit(habit.id)) { face }
    } else {
      Button(intent: ToggleHabitIntent(habitId: habit.id, dayKey: todayKey)) { face }
        .buttonStyle(.plain)
    }
  }
}

struct TodayBox: View {
  let habit: WidgetHabit
  let style: WidgetStyle

  var body: some View {
    let state = look()
    ZStack {
      RoundedRectangle(cornerRadius: 9).fill(state.fill)
      if !state.icon.isEmpty {
        Text(state.icon)
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(state.tint)
      }
    }
    .frame(width: 28, height: 28)
  }

  private func look() -> (fill: Color, icon: String, tint: Color) {
    switch habit.kind {
    case WidgetHabit.negative:
      let breached = habit.todayCount > 0
      return (
        breached ? habit.color.opacity(0.18) : habit.color,
        breached ? "✕" : "✓",
        breached ? style.content : .white
      )
    case WidgetHabit.quantitative:
      let ratio = min(1, max(0, habit.todayCount / habit.perDayTarget))
      return (habit.color.opacity(0.25 + 0.75 * ratio), "+", .white)
    default:
      return (
        habit.doneToday ? habit.color : habit.color.opacity(0.18),
        habit.doneToday ? "✓" : "",
        .white
      )
    }
  }
}
