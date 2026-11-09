import ActivityKit
import Flutter

enum FocusLiveActivity {
  static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      if call.method == "drain" {
        result([Any]())
      } else {
        result(nil)
      }
      return
    }
    switch call.method {
    case "show":
      show(call.arguments as? [String: Any] ?? [:])
      result(nil)
    case "hide":
      end()
      result(nil)
    case "drain":
      result([])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private static func show(_ arguments: [String: Any]) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let state = FocusAttributes.ContentState(
      title: arguments["title"] as? String ?? "",
      state: arguments["state"] as? String ?? "",
      phase: arguments["phase"] as? String ?? "running",
      running: arguments["running"] as? Bool ?? false,
      countDown: arguments["countDown"] as? Bool ?? true,
      seconds: (arguments["seconds"] as? NSNumber)?.intValue ?? 0,
      anchor: (arguments["anchor"] as? NSNumber)?.doubleValue ?? 0)
    let content = ActivityContent(state: state, staleDate: nil)
    if let current = Activity<FocusAttributes>.activities.first {
      Task { await current.update(content) }
      return
    }
    let attributes = FocusAttributes(habitId: arguments["habitId"] as? String ?? "")
    _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
  }

  @available(iOS 16.2, *)
  private static func end() {
    for activity in Activity<FocusAttributes>.activities {
      Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
  }
}
