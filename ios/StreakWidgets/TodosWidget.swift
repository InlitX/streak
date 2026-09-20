import SwiftUI
import WidgetKit

struct TodosEntry: TimelineEntry {
  let date: Date
  let all: Bool
}

struct TodosProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TodosEntry {
    TodosEntry(date: Date(), all: false)
  }

  func snapshot(for configuration: TodosConfigurationIntent, in context: Context) async -> TodosEntry {
    TodosEntry(date: Date(), all: configuration.all)
  }

  func timeline(for configuration: TodosConfigurationIntent, in context: Context) async -> Timeline<TodosEntry> {
    let dates = Timelines.dates()
    return Timeline(entries: dates.map { TodosEntry(date: $0, all: configuration.all) }, policy: .after(dates[1]))
  }
}

struct TodosWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "TodosWidgetProvider", intent: TodosConfigurationIntent.self, provider: TodosProvider()
    ) { entry in
      TodosView(entry: entry)
    }
    .configurationDisplayName("Tasks")
    .description("What is left for today")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct TodosView: View {
  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  let entry: TodosEntry

  private static let priorities: [Color?] = [
    nil, Color(argb: 0xFF3B82F6), Color(argb: 0xFFF59E0B), Color(argb: 0xFFEF4444),
  ]
  private static let done = Color(argb: 0xFF22C55E)
  private static let overdue = Color(argb: 0xFFEF4444)

  private var rows: Int { family == .systemLarge ? 8 : 3 }

  var body: some View {
    let style = WidgetStyle.of(scheme)
    let todos = TodosStore.due(all: entry.all, at: entry.date)
    let open = todos.filter { !$0.done }.count
    WidgetSurface(style) {
      VStack(alignment: .leading, spacing: 0) {
        Text(WidgetStrings.format("todos_open", "To-do  {count}", ["{count}": String(open)]))
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(style.content)
          .padding(.bottom, 6)
        if todos.isEmpty {
          Text(
            WidgetStrings.get(
              TodosStore.exists() ? "todos_empty" : "open_to_sync", "Nothing left for today")
          )
          .font(.system(size: 13))
          .foregroundStyle(style.muted)
        } else {
          ForEach(todos.prefix(rows), id: \.id) { todo in
            row(todo, style)
          }
        }
        Spacer(minLength: 0)
      }
      .widgetURL(Links.page("todos"))
    }
  }

  private func row(_ todo: WidgetTodo, _ style: WidgetStyle) -> some View {
    let overdue = !todo.done && todo.day >= 0 && todo.day < DayKeys.todayEpochDay(at: entry.date)
    let priority = TodosView.priorities.indices.contains(todo.priority) ? TodosView.priorities[todo.priority] : nil
    return HStack(spacing: 0) {
      Button(intent: ToggleTodoIntent(todoId: todo.id)) {
        ZStack {
          RoundedRectangle(cornerRadius: 7).fill(todo.done ? TodosView.done : style.cell)
          if todo.done {
            Text("✓")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
      Spacer().frame(width: 10)
      if let priority, !todo.done {
        Circle().fill(priority).frame(width: 7, height: 7)
        Spacer().frame(width: 7)
      }
      Text(todo.title)
        .font(.system(size: 14, weight: .medium))
        .strikethrough(todo.done)
        .foregroundStyle(todo.done ? style.muted : style.content)
        .lineLimit(1)
      Spacer(minLength: 8)
      let label = todo.done ? "" : trailing(todo, overdue: overdue)
      if !label.isEmpty {
        Text(label)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(overdue ? TodosView.overdue : style.muted)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 4)
  }

  private func trailing(_ todo: WidgetTodo, overdue: Bool) -> String {
    guard let minutes = todo.minutes else { return overdue ? "!" : "" }
    let hour = minutes / 60
    let rest = minutes % 60
    let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
    if !template.contains("a") {
      return String(format: "%02d:%02d", hour, rest)
    }
    let shown = hour % 12 == 0 ? 12 : hour % 12
    return String(format: "%d:%02d %@", shown, rest, hour < 12 ? "AM" : "PM")
  }
}
