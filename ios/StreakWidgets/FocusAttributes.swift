import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct FocusAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var state: String
    var phase: String
    var running: Bool
    var countDown: Bool
    var seconds: Int
    var anchor: Double
  }

  var habitId: String
}
