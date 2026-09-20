import SwiftUI
import WidgetKit

extension Color {
  init(argb: Int) {
    self.init(
      .sRGB,
      red: Double((argb >> 16) & 0xFF) / 255,
      green: Double((argb >> 8) & 0xFF) / 255,
      blue: Double(argb & 0xFF) / 255,
      opacity: Double((argb >> 24) & 0xFF) / 255)
  }
}

struct WidgetStyle {
  static let fallbackHabitColor = 0xFF7C3AED
  static let brand = Color(argb: 0xFF6C5CE7)

  let background: Color
  let content: Color
  let muted: Color
  let cell: Color

  static func of(_ scheme: ColorScheme) -> WidgetStyle {
    if scheme == .light {
      let content = Color(argb: 0xFF14141A)
      return WidgetStyle(
        background: Color(argb: 0xFFF5F5F7),
        content: content,
        muted: content.opacity(0.55),
        cell: content.opacity(0.14))
    }
    return WidgetStyle(
      background: Color(argb: 0xFF101014),
      content: .white,
      muted: .white.opacity(0.55),
      cell: .white.opacity(0.14))
  }
}

enum Links {
  static let app = URL(string: "streak://open")!

  static func habit(_ id: String) -> URL { link(["habit": id]) }

  static func focus(_ id: String) -> URL { link(["focus": id]) }

  static func page(_ name: String) -> URL { link(["page": name]) }

  private static func link(_ query: [String: String]) -> URL {
    var components = URLComponents()
    components.scheme = "streak"
    components.host = "open"
    components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
    return components.url ?? app
  }
}

struct WidgetSurface<Content: View>: View {
  let style: WidgetStyle
  let content: Content

  init(_ style: WidgetStyle, @ViewBuilder content: () -> Content) {
    self.style = style
    self.content = content()
  }

  var body: some View {
    content
      .containerBackground(for: .widget) { style.background }
  }
}

struct StreakBadge: View {
  let streak: Int
  let color: Color
  let style: WidgetStyle

  var body: some View {
    if streak > 0 {
      HStack(spacing: 2) {
        Image(systemName: "flame.fill")
          .font(.system(size: 11))
          .foregroundStyle(color)
        Text(streak > 999 ? "999+" : String(streak))
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(style.content)
          .lineLimit(1)
      }
      .padding(.leading, 5)
    }
  }
}

struct PendingFlame: View {
  let color: Color
  let faint: Bool

  var body: some View {
    Image(systemName: "flame")
      .font(.system(size: 14))
      .foregroundStyle(color.opacity(faint ? 0.16 : 0.3))
  }
}

struct CompletionIndicator: View {
  let done: Bool
  let color: Color

  var body: some View {
    if done {
      Image(systemName: "flame.fill")
        .font(.system(size: 18))
        .foregroundStyle(color)
    } else {
      PendingFlame(color: color, faint: false)
    }
  }
}

struct EmptyMessage: View {
  let text: String
  let style: WidgetStyle

  var body: some View {
    Text(text)
      .font(.system(size: 13))
      .foregroundStyle(style.muted)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.top, 8)
  }
}
