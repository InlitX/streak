import Foundation
import WidgetKit

enum WidgetActions {
  static let maxQueue = 200

  static func toggleHabit(_ habitId: String, dayKey: String) {
    guard let payload = Payload.load(), let habit = payload.habits.first(where: { $0.id == habitId }),
      !habit.opensApp
    else { return }
    let delta = habit.kind == WidgetHabit.quantitative ? habit.incrementAmount : 1
    if Optimistic.apply(habitId: habitId, dayKey: dayKey, delta: delta) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    let action = habit.kind == WidgetHabit.quantitative ? "progress" : "toggle"
    push("streak://toggleHabit?habitId=\(habitId)&day=\(dayKey)&action=\(action)&delta=\(Amounts.format(delta))")
  }

  static func toggleTodo(_ id: String) {
    if TodosStore.toggleDone(id) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    push("streak://toggleTodo?todoId=\(id)")
  }

  static func push(_ uri: String) {
    var queue = readQueue()
    guard queue.count < maxQueue else { return }
    queue.append(uri)
    Shared.write(Shared.queueKey, queue)
  }

  static func readQueue() -> [String] {
    guard let raw = Shared.defaults?.string(forKey: Shared.queueKey), !raw.isEmpty,
      let data = raw.data(using: .utf8)
    else { return [] }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String] ?? []
  }
}

enum Optimistic {
  static func apply(habitId: String, dayKey: String, delta: Double) -> Bool {
    guard var root = Shared.object(Shared.habitsKey), let days = root["days"] as? [[String: Any]],
      var habits = root["habits"] as? [[String: Any]]
    else { return false }
    let todayKey = Payload.todayKey(of: root, at: Date())
    let day = Payload.index(of: dayKey, in: days)
    let today = Payload.index(of: todayKey, in: days)
    guard day >= 0, let index = habits.firstIndex(where: { ($0["id"] as? String) == habitId }) else {
      return false
    }
    guard mutate(&habits[index], day: day, today: today, delta: delta) else { return false }
    root["habits"] = habits
    resummarize(&root, habits: habits, today: today)
    Shared.write(Shared.habitsKey, root)
    return true
  }

  private static func mutate(_ habit: inout [String: Any], day: Int, today: Int, delta: Double) -> Bool {
    guard var completions = habit["completions"] as? [Bool], var counts = habit["counts"] as? [Double],
      completions.count > day, counts.count > day
    else { return false }
    let kind = habit["kind"] as? Int ?? 0
    let target = max(1, habit["perDayTarget"] as? Double ?? 1)
    let count = counts[day]
    let newCount: Double
    let done: Bool
    switch kind {
    case WidgetHabit.negative:
      newCount = count > 0 ? 0 : 1
      done = newCount == 0
    case WidgetHabit.quantitative:
      newCount = max(0, count + delta)
      done = newCount >= target
    default:
      done = count < target
      newCount = done ? target : 0
    }
    counts[day] = newCount
    completions[day] = done
    habit["counts"] = counts
    habit["completions"] = completions
    putLevel(&habit, day: day, today: today, level: Levels.level(kind: kind, count: newCount, target: target))
    return true
  }

  private static func putLevel(_ habit: inout [String: Any], day: Int, today: Int, level: Int) {
    guard today >= 0, var heatmap = habit["heatmap"] as? [Int],
      let last = heatmap.lastIndex(where: { $0 != -1 })
    else { return }
    let index = last - (today - day)
    if heatmap.indices.contains(index) {
      heatmap[index] = level
      habit["heatmap"] = heatmap
    }
  }

  private static func resummarize(_ root: inout [String: Any], habits: [[String: Any]], today: Int) {
    guard today >= 0, var summary = root["summary"] as? [String: Any] else { return }
    var done = 0
    for habit in habits {
      if let scheduled = habit["scheduled"] as? [Bool], today < scheduled.count, !scheduled[today] {
        continue
      }
      if let completions = habit["completions"] as? [Bool], completions.count > today, completions[today] {
        done += 1
      }
    }
    summary["doneToday"] = done
    root["summary"] = summary
  }
}
