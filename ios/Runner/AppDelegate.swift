import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var channel: FlutterMethodChannel?
  private var coversContent = false
  private let cover = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
  private let links = StreakLinks()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(hideContent),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(showContent),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StreakAppDelegate")
    else {
      return
    }
    registrar.addSceneDelegate(links)
    let channel = FlutterMethodChannel(
      name: "streak/app_icon", binaryMessenger: registrar.messenger())
    links.channel = channel
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      let arguments = call.arguments as? [String: Any]
      switch call.method {
      case "setSecure":
        self?.coversContent = arguments?["secure"] as? Bool ?? false
        result(true)
      case "setIcon":
        let icon = arguments?["icon"] as? String ?? "default"
        UIApplication.shared.setAlternateIconName(icon == "default" ? nil : "AppIcon-\(icon)")
        result(true)
      case "consumeLaunchHabit":
        result(self?.links.consume("habit"))
      case "consumeLaunchFocus":
        result(self?.links.consume("focus"))
      case "consumeLaunchPage":
        result(self?.links.consume("page"))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @objc private func hideContent() {
    guard coversContent, let window = activeWindow else { return }
    cover.frame = window.bounds
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
  }

  @objc private func showContent() {
    cover.removeFromSuperview()
  }

  private var activeWindow: UIWindow? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    return windows.first { $0.isKeyWindow } ?? windows.first
  }
}

class StreakLinks: NSObject, FlutterSceneLifeCycleDelegate {
  var channel: FlutterMethodChannel?

  private var pending: [String: String] = [:]
  private let methods = ["habit": "openHabit", "focus": "startFocus", "page": "openPage"]

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UISceneConnectionOptions?
  ) -> Bool {
    for context in connectionOptions?.urlContexts ?? [] {
      if case let (key, value)? = target(of: context.url) {
        pending[key] = value
      }
    }
    return false
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where context.url.scheme == "streak" {
      handled = true
      if case let (key, value)? = target(of: context.url), let method = methods[key] {
        channel?.invokeMethod(method, arguments: value)
      }
    }
    return handled
  }

  func consume(_ key: String) -> String? {
    pending.removeValue(forKey: key)
  }

  private func target(of url: URL) -> (String, String)? {
    guard url.scheme == "streak",
      let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
    else { return nil }
    for item in items where methods[item.name] != nil {
      if let value = item.value, !value.isEmpty {
        return (item.name, value)
      }
    }
    return nil
  }
}
