#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {
constexpr UINT_PTR kShowFallbackTimer = 1;
constexpr UINT kShowFallbackMs = 4000;
constexpr UINT_PTR kRefitTimer = 2;
constexpr UINT kRefitMs = 600;
constexpr wchar_t kWindowKey[] = L"Software\\Streak";
constexpr wchar_t kPlacementValue[] = L"WindowPlacement";
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayId = 1;
constexpr UINT kTrayOpen = 1;
constexpr UINT kTrayQuit = 2;

std::wstring WideFromUtf8(const std::string& text) {
  if (text.empty()) return std::wstring();
  int length = MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                   static_cast<int>(text.size()), nullptr, 0);
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      wide.data(), length);
  return wide;
}
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
    if (call.method_name() == "tray") {
      SetTray(call.arguments());
      result->Success();
      return;
    }
    const auto* on = std::get_if<bool>(call.arguments());
    if (call.method_name() != "fullscreen" || on == nullptr) {
      result->NotImplemented();
      return;
    }
    SetFullscreen(*on);
    result->Success();
  });
  island_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "streak/island",
          &flutter::StandardMethodCodec::GetInstance());
  island_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleIsland(call, std::move(result));
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

void FlutterWindow::HandleIsland(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();
  const auto* args = call.arguments();
  if (method == "open") {
    if (!island_) {
      int64_t id = 0;
      if (const auto* low = std::get_if<int32_t>(args)) id = *low;
      if (const auto* wide = std::get_if<int64_t>(args)) id = *wide;
      island_ = std::make_unique<IslandWindow>(
          FlutterDesktopEngineForId(id), [this](const char* event, bool on) {
            if (island_channel_) {
              island_channel_->InvokeMethod(
                  event, std::make_unique<flutter::EncodableValue>(on));
            }
          });
      if (!island_->Create()) {
        island_ = nullptr;
        result->Error("island", "Could not create the island window");
        return;
      }
    }
    result->Success(flutter::EncodableValue(island_->view_id()));
    return;
  }
  if (method == "close") {
    island_ = nullptr;
    result->Success();
    return;
  }
  if (method == "app") {
    BringToFront();
    result->Success();
    return;
  }
  if (!island_) {
    result->Success();
    return;
  }
  if (method == "shape") {
    std::vector<POINT> points;
    if (const auto* list = std::get_if<std::vector<int32_t>>(args)) {
      for (size_t i = 0; i + 1 < list->size(); i += 2) {
        points.push_back({(*list)[i], (*list)[i + 1]});
      }
    }
    island_->SetShape(points);
  } else if (method == "keyboard") {
    const auto* take = std::get_if<bool>(args);
    island_->TakeKeyboard(take != nullptr && *take);
  } else if (method == "size") {
    if (const auto* list = std::get_if<std::vector<int32_t>>(args)) {
      if (list->size() == 2) island_->SetSize((*list)[0], (*list)[1]);
    }
  } else {
    result->NotImplemented();
    return;
  }
  result->Success();
}

void FlutterWindow::BringToFront() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) return;
  if (in_tray_) {
    ShowFromTray();
    return;
  }
  if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
  if (!IsWindowVisible(hwnd)) ShowWindow(hwnd, SW_SHOW);
  SetForegroundWindow(hwnd);
}

void FlutterWindow::SetTray(const flutter::EncodableValue* args) {
  const auto* map = std::get_if<flutter::EncodableMap>(args);
  if (map == nullptr) return;
  auto text = [map](const char* key) -> std::wstring {
    auto found = map->find(flutter::EncodableValue(key));
    if (found == map->end()) return std::wstring();
    const auto* value = std::get_if<std::string>(&found->second);
    return value == nullptr ? std::wstring() : WideFromUtf8(*value);
  };
  auto on = map->find(flutter::EncodableValue("on"));
  if (on != map->end()) {
    const auto* flag = std::get_if<bool>(&on->second);
    tray_enabled_ = flag != nullptr && *flag;
  }
  std::wstring open = text("open");
  std::wstring quit = text("quit");
  if (!open.empty()) tray_open_ = open;
  if (!quit.empty()) tray_quit_ = quit;
  if (!tray_enabled_ && in_tray_) ShowFromTray();
}

void FlutterWindow::HideToTray() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr || in_tray_) return;
  SavePlacement();
  ShowWindow(hwnd, SW_HIDE);
  in_tray_ = true;
  AddTrayIcon();
}

void FlutterWindow::ShowFromTray() {
  HWND hwnd = GetHandle();
  RemoveTrayIcon();
  in_tray_ = false;
  if (hwnd == nullptr) return;
  ShowWindow(hwnd, SW_SHOW);
  if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
  SetForegroundWindow(hwnd);
}

void FlutterWindow::AddTrayIcon() {
  NOTIFYICONDATAW data = {sizeof(data)};
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = static_cast<HICON>(LoadImageW(
      GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON), IMAGE_ICON,
      GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0));
  wcscpy_s(data.szTip, L"Streak");
  Shell_NotifyIconW(NIM_ADD, &data);
  if (data.hIcon != nullptr) DestroyIcon(data.hIcon);
}

void FlutterWindow::RemoveTrayIcon() {
  NOTIFYICONDATAW data = {sizeof(data)};
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  Shell_NotifyIconW(NIM_DELETE, &data);
}

void FlutterWindow::ShowTrayMenu() {
  HWND hwnd = GetHandle();
  HMENU menu = CreatePopupMenu();
  if (menu == nullptr) return;
  AppendMenuW(menu, MF_STRING, kTrayOpen, tray_open_.c_str());
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kTrayQuit, tray_quit_.c_str());
  SetMenuDefaultItem(menu, kTrayOpen, FALSE);
  POINT cursor;
  GetCursorPos(&cursor);
  SetForegroundWindow(hwnd);
  UINT picked = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY,
                               cursor.x, cursor.y, 0, hwnd, nullptr);
  PostMessage(hwnd, WM_NULL, 0, 0);
  DestroyMenu(menu);
  if (picked == kTrayOpen) {
    ShowFromTray();
  } else if (picked == kTrayQuit) {
    RemoveTrayIcon();
    in_tray_ = false;
    PostMessage(hwnd, WM_CLOSE, 0, 0);
  }
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
  SetTimer(GetHandle(), kRefitTimer, kRefitMs, nullptr);
}

void FlutterWindow::Refit() {
  if (!flutter_controller_ || !flutter_controller_->view()) {
    return;
  }
  HWND view = flutter_controller_->view()->GetNativeWindow();
  RECT frame = GetClientArea();
  const int width = frame.right - frame.left;
  const int height = frame.bottom - frame.top;
  if (width < 2 || height < 2) {
    return;
  }
  MoveWindow(view, frame.left, frame.top, width, height - 1, FALSE);
  MoveWindow(view, frame.left, frame.top, width, height, TRUE);
  flutter_controller_->ForceRedraw();
}

void FlutterWindow::OnDestroy() {
  if (in_tray_) {
    RemoveTrayIcon();
    in_tray_ = false;
  }
  window_channel_ = nullptr;
  island_channel_ = nullptr;
  island_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_SYSCOMMAND && (wparam & 0xFFF0) == SC_MINIMIZE &&
      tray_enabled_) {
    HideToTray();
    return 0;
  }
  if (message == kTrayMessage) {
    switch (LOWORD(lparam)) {
      case WM_LBUTTONUP:
      case WM_LBUTTONDBLCLK:
        ShowFromTray();
        break;
      case WM_RBUTTONUP:
      case WM_CONTEXTMENU:
        ShowTrayMenu();
        break;
    }
    return 0;
  }
  if (message == kShowFromTray) {
    BringToFront();
    return 0;
  }
  if (message == taskbar_created_ && in_tray_) {
    AddTrayIcon();
    return 0;
  }
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
      if (wparam == kRefitTimer) {
        KillTimer(hwnd, kRefitTimer);
        Refit();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
