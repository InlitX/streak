#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {
constexpr UINT_PTR kShowFallbackTimer = 1;
constexpr UINT kShowFallbackMs = 4000;
constexpr wchar_t kWindowKey[] = L"Software\\Streak";
constexpr wchar_t kPlacementValue[] = L"WindowPlacement";
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }
  RestorePlacement();

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "streak/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    const auto* on = std::get_if<bool>(call.arguments());
    if (call.method_name() != "fullscreen" || on == nullptr) {
      result->NotImplemented();
      return;
    }
    SetFullscreen(*on);
    result->Success();
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    KillTimer(this->GetHandle(), kShowFallbackTimer);
    this->Reveal();
  });

  SetTimer(GetHandle(), kShowFallbackTimer, kShowFallbackMs, nullptr);

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::SetFullscreen(bool on) {
  HWND hwnd = GetHandle();
  if (on == fullscreen_ || hwnd == nullptr) {
    return;
  }
  fullscreen_ = on;
  if (on) {
    windowed_style_ = GetWindowLong(hwnd, GWL_STYLE);
    GetWindowPlacement(hwnd, &windowed_placement_);
    MONITORINFO monitor = {sizeof(monitor)};
    GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
    const RECT& area = monitor.rcMonitor;
    SetWindowLong(hwnd, GWL_STYLE, windowed_style_ & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(hwnd, HWND_TOP, area.left, area.top, area.right - area.left,
                 area.bottom - area.top, SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    return;
  }
  SetWindowLong(hwnd, GWL_STYLE, windowed_style_);
  SetWindowPlacement(hwnd, &windowed_placement_);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER |
                   SWP_FRAMECHANGED);
}

void FlutterWindow::RestorePlacement() {
  WINDOWPLACEMENT placement = {};
  DWORD size = sizeof(placement);
  if (RegGetValueW(HKEY_CURRENT_USER, kWindowKey, kPlacementValue,
                   RRF_RT_REG_BINARY, nullptr, &placement,
                   &size) != ERROR_SUCCESS ||
      size != sizeof(placement) || placement.length != sizeof(placement)) {
    return;
  }
  const RECT& rect = placement.rcNormalPosition;
  if (rect.right <= rect.left || rect.bottom <= rect.top) {
    return;
  }
  maximized_ = placement.showCmd == SW_SHOWMAXIMIZED ||
               (placement.showCmd == SW_SHOWMINIMIZED &&
                (placement.flags & WPF_RESTORETOMAXIMIZED));
  placement.showCmd = SW_HIDE;
  placement.flags = 0;
  SetWindowPlacement(GetHandle(), &placement);
}

void FlutterWindow::SavePlacement() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr || !IsWindowVisible(hwnd)) {
    return;
  }
  WINDOWPLACEMENT placement = {sizeof(placement)};
  if (fullscreen_) {
    placement = windowed_placement_;
  } else if (!GetWindowPlacement(hwnd, &placement)) {
    return;
  }
  RegSetKeyValueW(HKEY_CURRENT_USER, kWindowKey, kPlacementValue, REG_BINARY,
                  &placement, sizeof(placement));
}

void FlutterWindow::Reveal() {
  ShowWindow(GetHandle(), maximized_ ? SW_SHOWMAXIMIZED : SW_SHOWNORMAL);
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE) {
    SavePlacement();
  }
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TIMER:
      if (wparam == kShowFallbackTimer) {
        KillTimer(hwnd, kShowFallbackTimer);
        Reveal();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
