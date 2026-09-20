import SwiftUI

enum Shared {
  static let group = "group.com.streak.app"
  static let habitsKey = "habits_data"
  static let todosKey = "todos_data"
  static let stringsKey = "widget_strings"
  static let queueKey = "pending_actions"

  static var defaults: UserDefaults? { UserDefaults(suiteName: group) }

  static func object(_ key: String) -> [String: Any]? {
    guard let raw = defaults?.string(forKey: key), let data = raw.data(using: .utf8) else {
      return nil
    }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
  }

  static func write(_ key: String, _ object: Any) {
    guard let data = try? JSONSerialization.data(withJSONObject: object),
      let raw = String(data: data, encoding: .utf8)
    else { return }
    defaults?.set(raw, forKey: key)
  }
}

enum WidgetStrings {
  static func get(_ key: String, _ fallback: String) -> String {
    let value = Shared.object(Shared.stringsKey)?[key] as? String ?? ""
    return value.isEmpty ? fallback : value
  }

  static func format(_ key: String, _ fallback: String, _ subs: [String: String]) -> String {
    var result = get(key, fallback)
    for (token, value) in subs {
      result = result.replacingOccurrences(of: token, with: value)
    }
    return result
  }
}

enum DayKeys {
  static func system(at date: Date, cutoff: Int) -> String {
    let calendar = Calendar.current
    let shifted = calendar.date(byAdding: .hour, value: -cutoff, to: date) ?? date
    let parts = calendar.dateComponents([.day, .month, .year], from: shifted)
    return String(format: "%02d-%02d-%04d", parts.day ?? 1, parts.month ?? 1, parts.year ?? 2000)
  }

  static func nextDayStart(after date: Date, cutoff: Int) -> Date {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: date)
    let todayCutoff = calendar.date(byAdding: .hour, value: cutoff, to: start) ?? start
    if todayCutoff > date {
      return todayCutoff
    }
    return calendar.date(byAdding: .day, value: 1, to: todayCutoff)
      ?? todayCutoff.addingTimeInterval(86400)
  }

  static func todayEpochDay(at date: Date) -> Int {
    let start = Calendar.current.startOfDay(for: date)
    return Int(floor((start.timeIntervalSince1970 + Double(TimeZone.current.secondsFromGMT(for: start))) / 86400))
  }
}

enum Amounts {
  static func format(_ value: Double) -> String {
    let rounded = (value * 100).rounded() / 100
    if rounded == rounded.rounded(.down) {
      return String(Int64(rounded))
    }
    var text = String(format: "%.2f", rounded)
    while text.hasSuffix("0") { text.removeLast() }
    if text.hasSuffix(".") { text.removeLast() }
    return text
  }

  static func compact(_ value: Double) -> String {
    value < 1000 ? format(value) : compact(Int(value.rounded()))
  }

  static func compact(_ value: Int) -> String {
    if value < 1000 { return String(value) }
    if value < 10000 {
      let tenths = (value + 50) / 100
      return tenths % 10 == 0 ? "\(tenths / 10)k" : "\(tenths / 10).\(tenths % 10)k"
    }
    if value < 1000000 { return "\((value + 500) / 1000)k" }
    return "\((value + 500000) / 1000000)M"
  }
}

enum Levels {
  static func level(kind: Int, count: Double, target: Double) -> Int {
    if kind == 1 { return count > 0 ? 0 : 4 }
    if count <= 0 { return 0 }
    return min(4, max(1, Int(ceil(count / max(1, target) * 4))))
  }
}

struct WidgetHabit {
  static let positive = 0
  static let negative = 1
  static let quantitative = 2

  let id: String
  let name: String
  let description: String
  let color: Color
  let icon: UIImage?
  let iconTintable: Bool
  let completions: [Bool]
  let counts: [Double]
  let scheduled: [Bool]?
  let kind: Int
  let focusOnly: Bool
  let streak: Int
  let perDayTarget: Double
  let incrementAmount: Double
  let heatmap: [Int]

  var doneToday: Bool { completions.count > Payload.today && completions[Payload.today] }
  var todayCount: Double { counts.count > Payload.today ? counts[Payload.today] : 0 }
  var quantified: Bool { kind == WidgetHabit.quantitative || perDayTarget > 1 }
  var opensApp: Bool { focusOnly || kind == WidgetHabit.negative }

  init(_ raw: [String: Any]) {
    id = raw["id"] as? String ?? ""
    name = raw["name"] as? String ?? ""
    description = raw["description"] as? String ?? ""
    color = Color(argb: raw["color"] as? Int ?? WidgetStyle.fallbackHabitColor)
    icon = Payload.image(raw["iconData"] as? String)
    iconTintable = raw["iconTintable"] as? Bool ?? true
    completions = raw["completions"] as? [Bool] ?? []
    counts = raw["counts"] as? [Double] ?? []
    scheduled = raw["scheduled"] as? [Bool]
    kind = raw["kind"] as? Int ?? 0
    focusOnly = raw["focusOnly"] as? Bool ?? false
    streak = raw["streak"] as? Int ?? 0
    perDayTarget = max(1, raw["perDayTarget"] as? Double ?? 1)
    incrementAmount = max(0.01, raw["incrementAmount"] as? Double ?? 1)
    heatmap = raw["heatmap"] as? [Int] ?? []
  }
}

struct WidgetDay {
  let key: String
  let label: String
  let isToday: Bool
}

struct WidgetSummary {
  let doneToday: Int
  let total: Int
  let bestStreak: Int
  let weekDone: Int
}

struct Payload {
  static let week = 7
  static let today = week - 1

  let habits: [WidgetHabit]
  let days: [WidgetDay]
  let todayKey: String
  let dayCutoff: Int
  let summary: WidgetSummary
  let heatmap: [Int]
  let fallbackIcon: UIImage?

  static func cutoff(of root: [String: Any]) -> Int {
    min(6, max(0, root["dayCutoff"] as? Int ?? 0))
  }

  static func todayKey(of root: [String: Any], at date: Date) -> String {
    let stored = root["todayKey"] as? String ?? ""
    let system = DayKeys.system(at: date, cutoff: cutoff(of: root))
    let days = root["days"] as? [[String: Any]] ?? []
    if index(of: system, in: days) >= 0 || stored.isEmpty {
      return system
    }
    return stored
  }

  static func index(of key: String, in days: [[String: Any]]) -> Int {
    days.firstIndex { ($0["key"] as? String) == key } ?? -1
  }

  static func load(at date: Date = Date()) -> Payload? {
    guard let raw = Shared.object(Shared.habitsKey) else { return nil }
    let todayKey = todayKey(of: raw, at: date)
    let root = align(raw, todayKey: todayKey)
    let summary = root["summary"] as? [String: Any] ?? [:]
    return Payload(
      habits: (root["habits"] as? [[String: Any]] ?? []).map(WidgetHabit.init),
      days: (root["days"] as? [[String: Any]] ?? []).map {
        WidgetDay(
          key: $0["key"] as? String ?? "",
          label: $0["label"] as? String ?? "",
          isToday: $0["isToday"] as? Bool ?? false)
      },
      todayKey: todayKey,
      dayCutoff: cutoff(of: root),
      summary: WidgetSummary(
        doneToday: summary["doneToday"] as? Int ?? 0,
        total: summary["total"] as? Int ?? 0,
        bestStreak: summary["bestStreak"] as? Int ?? 0,
        weekDone: summary["weekDone"] as? Int ?? 0),
      heatmap: root["heatmap"] as? [Int] ?? [],
      fallbackIcon: image(root["fallbackIconData"] as? String))
  }

  static func align(_ raw: [String: Any], todayKey: String) -> [String: Any] {
    var root = raw
    let days = root["days"] as? [[String: Any]] ?? []
    guard days.count > week else { return root }
    let end = index(of: todayKey, in: days)
    let start = end < 0 ? days.count - week : (end < today ? 0 : end - today)
    root["days"] = (start..<start + week).compactMap { i -> [String: Any]? in
      guard i < days.count else { return nil }
      var day = days[i]
      day["isToday"] = (day["key"] as? String) == todayKey
      return day
    }
    guard var habits = root["habits"] as? [[String: Any]] else { return root }
    var due = 0
    var doneToday = 0
    var weekDone = 0
    var scheduling = false
    for i in habits.indices {
      var habit = habits[i]
      let scheduled = habit["scheduled"] as? [Bool]
      let completions = slice(habit["completions"] as? [Bool] ?? [], from: start, fill: false)
      habit["completions"] = completions
      habit["counts"] = slice(habit["counts"] as? [Double] ?? [], from: start, fill: 0)
      if let scheduled {
        habit["scheduled"] = slice(scheduled, from: start, fill: false)
      }
      weekDone += completions.filter { $0 }.count
      if let scheduled {
        scheduling = true
        if end >= 0, end < scheduled.count, scheduled[end] {
          due += 1
          if completions[today] { doneToday += 1 }
        }
      }
      habits[i] = habit
    }
    root["habits"] = habits
    if scheduling, end - start == today, var summary = root["summary"] as? [String: Any] {
      summary["total"] = due
      summary["doneToday"] = doneToday
      summary["weekDone"] = weekDone
      root["summary"] = summary
    }
    return root
  }

  static func slice<T>(_ values: [T], from start: Int, fill: T) -> [T] {
    (start..<start + week).map { $0 < values.count && $0 >= 0 ? values[$0] : fill }
  }

  static func image(_ base64: String?) -> UIImage? {
    guard let base64, let data = Data(base64Encoded: base64) else { return nil }
    return UIImage(data: data)
  }
}

struct WidgetTodo {
  let id: String
  let title: String
  let day: Int
  let priority: Int
  let done: Bool
  let minutes: Int?

  init(_ raw: [String: Any]) {
    id = raw["id"] as? String ?? ""
    title = raw["title"] as? String ?? ""
    day = raw["day"] as? Int ?? -1
    priority = raw["priority"] as? Int ?? 0
    done = raw["done"] as? Bool ?? false
    minutes = raw["minutes"] as? Int
  }
}

enum TodosStore {
  static func exists() -> Bool { Shared.object(Shared.todosKey) != nil }

  static func due(all: Bool, at date: Date) -> [WidgetTodo] {
    let todos = (Shared.object(Shared.todosKey)?["todos"] as? [[String: Any]] ?? []).map(WidgetTodo.init)
    let today = DayKeys.todayEpochDay(at: date)
    return todos.filter { all || $0.done || $0.day < 0 || $0.day <= today }
  }

  static func toggleDone(_ id: String) -> Bool {
    guard var root = Shared.object(Shared.todosKey), var todos = root["todos"] as? [[String: Any]],
      let index = todos.firstIndex(where: { ($0["id"] as? String) == id })
    else { return false }
    todos[index]["done"] = !(todos[index]["done"] as? Bool ?? false)
    root["todos"] = todos
    Shared.write(Shared.todosKey, root)
    return true
  }
}
