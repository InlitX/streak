import SwiftUI
import WidgetKit

@main
struct StreakWidgets: WidgetBundle {
  var body: some Widget {
    HabitGridWidget()
    TodayWidget()
    StatsWidget()
    TodosWidget()
    HeatmapWidget()
  }
}

struct StreakEntry: TimelineEntry {
  let date: Date
  let payload: Payload?
}

enum Timelines {
  static func dates() -> [Date] {
    let now = Date()
    let cutoff = Payload.load(at: now)?.dayCutoff ?? 0
    return [now, DayKeys.nextDayStart(after: now, cutoff: cutoff)]
  }
}

struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry {
    StreakEntry(date: Date(), payload: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    completion(StreakEntry(date: Date(), payload: Payload.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    let dates = Timelines.dates()
    let entries = dates.map { StreakEntry(date: $0, payload: Payload.load(at: $0)) }
    completion(Timeline(entries: entries, policy: .after(dates[1])))
  }
}
