import ActivityKit
import SwiftUI
import WidgetKit

struct FocusActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusAttributes.self) { context in
      FocusLockView(state: context.state)
        .padding(16)
        .activityBackgroundTint(Color(argb: 0xFF101014))
        .activitySystemActionForegroundColor(.white)
        .widgetURL(Links.page("focusPage"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "timer").foregroundStyle(WidgetStyle.brand)
        }
        DynamicIslandExpandedRegion(.trailing) {
          FocusClock(state: context.state).font(.system(size: 22, weight: .bold))
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
        }
      } compactLeading: {
        Image(systemName: "timer").foregroundStyle(WidgetStyle.brand)
      } compactTrailing: {
        FocusClock(state: context.state).frame(maxWidth: 52).font(.system(size: 13, weight: .semibold))
      } minimal: {
        Image(systemName: "timer").foregroundStyle(WidgetStyle.brand)
      }
      .widgetURL(Links.page("focusPage"))
    }
  }
}

struct FocusLockView: View {
  let state: FocusAttributes.ContentState

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text(state.title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .lineLimit(1)
        Text(state.state)
          .font(.system(size: 12))
          .foregroundStyle(.white.opacity(0.6))
          .lineLimit(1)
      }
      Spacer(minLength: 8)
      FocusClock(state: state)
        .font(.system(size: 30, weight: .bold))
        .foregroundStyle(.white)
    }
  }
}

struct FocusClock: View {
  let state: FocusAttributes.ContentState

  private var anchor: Date { Date(timeIntervalSince1970: state.anchor / 1000) }

  var body: some View {
    Group {
      if state.running && state.countDown {
        Text(timerInterval: Date.now...max(anchor, Date.now.addingTimeInterval(1)), countsDown: true)
      } else if state.running && state.anchor > 0 {
        Text(anchor, style: .timer)
      } else {
        Text(Self.format(state.seconds))
      }
    }
    .monospacedDigit()
    .multilineTextAlignment(.trailing)
  }

  static func format(_ seconds: Int) -> String {
    let total = max(0, seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let rest = total % 60
    if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, rest) }
    return String(format: "%d:%02d", minutes, rest)
  }
}
