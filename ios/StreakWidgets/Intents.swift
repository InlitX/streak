import AppIntents
import WidgetKit

struct ToggleHabitIntent: AppIntent {
  static var title: LocalizedStringResource = "Mark habit"
  static var isDiscoverable = false

  @Parameter(title: "Habit") var habitId: String
  @Parameter(title: "Day") var dayKey: String

  init() {}

  init(habitId: String, dayKey: String) {
    self.habitId = habitId
    self.dayKey = dayKey
  }

  func perform() async throws -> some IntentResult {
    WidgetActions.toggleHabit(habitId, dayKey: dayKey)
    return .result()
  }
}

struct ToggleTodoIntent: AppIntent {
  static var title: LocalizedStringResource = "Mark task"
  static var isDiscoverable = false

  @Parameter(title: "Task") var todoId: String

  init() {}

  init(todoId: String) {
    self.todoId = todoId
  }

  func perform() async throws -> some IntentResult {
    WidgetActions.toggleTodo(todoId)
    return .result()
  }
}

struct HabitEntity: AppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
  static var defaultQuery = HabitQuery()

  let id: String
  let name: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

struct HabitQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [HabitEntity] {
    all().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [HabitEntity] {
    all()
  }

  private func all() -> [HabitEntity] {
    (Payload.load()?.habits ?? []).map { HabitEntity(id: $0.id, name: $0.name) }
  }
}

enum HeatmapStyle: String, AppEnum {
  case classic
  case card

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Style")
  static var caseDisplayRepresentations: [HeatmapStyle: DisplayRepresentation] = [
    .classic: DisplayRepresentation(title: "Classic"),
    .card: DisplayRepresentation(title: "Card"),
  ]
}

struct HeatmapConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Heatmap"
  static var description = IntentDescription("One habit, or all of them together")

  @Parameter(title: "Habit") var habit: HabitEntity?
  @Parameter(title: "Style", default: .classic) var style: HeatmapStyle
}

struct TodosConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Tasks"
  static var description = IntentDescription("Today's tasks, or every task")

  @Parameter(title: "Show every task", default: false) var all: Bool
}
