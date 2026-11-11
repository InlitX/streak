import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "Streak"
    self.minSize = NSSize(width: 360, height: 560)
    self.collectionBehavior.insert(.fullScreenPrimary)

    let visible = (self.screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 820)
    let width = min(1280, visible.width * 0.9)
    let height = min(820, visible.height * 0.9)
    let frame = NSRect(
      x: visible.midX - width / 2,
      y: visible.midY - height / 2,
      width: width,
      height: height
    )
    self.setFrame(frame, display: true)
    self.setFrameAutosaveName("StreakMainWindow")

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "streak/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      if call.method == "fullscreen", let on = call.arguments as? Bool {
        let isFull = self.styleMask.contains(.fullScreen)
        if on != isFull {
          self.toggleFullScreen(nil)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel

    super.awakeFromNib()
  }
}
