#include "island_window.h"

#include <dwmapi.h>
#include <shellapi.h>

namespace {
constexpr wchar_t kClass[] = L"STREAK_ISLAND";
constexpr UINT_PTR kWatchTimer = 1;
constexpr UINT kWatchMs = 700;

bool IsShell(HWND window) {
  wchar_t name[64] = {};
  GetClassNameW(window, name, 64);
  return wcscmp(name, L"Progman") == 0 || wcscmp(name, L"WorkerW") == 0 ||
         wcscmp(name, L"Shell_TrayWnd") == 0 ||
         wcscmp(name, L"Shell_SecondaryTrayWnd") == 0;
}
}

IslandWindow::IslandWindow(FlutterDesktopEngineRef engine,
                           std::function<void(const char*, bool)> notify)
    : engine_(engine), notify_(std::move(notify)) {}

IslandWindow::~IslandWindow() {
  if (window_) KillTimer(window_, kWatchTimer);
  content_ = nullptr;
  if (controller_) {
    FlutterDesktopViewControllerRef controller = controller_;
    controller_ = nullptr;
    FlutterDesktopViewControllerDestroy(controller);
  }
  if (window_) {
    HWND window = window_;
    window_ = nullptr;
    DestroyWindow(window);
  }
}

bool IslandWindow::Create() {
  static bool registered = false;
  HINSTANCE instance = GetModuleHandle(nullptr);
  if (!registered) {
    WNDCLASSEXW type = {sizeof(type)};
    type.lpfnWndProc = Proc;
    type.hInstance = instance;
    type.hCursor = LoadCursor(nullptr, IDC_ARROW);
    type.hbrBackground = static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
    type.lpszClassName = kClass;
    if (!RegisterClassExW(&type)) return false;
    registered = true;
  }

  window_ = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_TOPMOST | WS_EX_NOACTIVATE,
                            kClass, L"Streak", WS_POPUP, 0, 0, 1, 1, nullptr,
                            nullptr, instance, this);
  if (!window_) return false;

  MARGINS margins = {-1, -1, -1, -1};
  DwmExtendFrameIntoClientArea(window_, &margins);
  DWORD corners = 1;
  DwmSetWindowAttribute(window_, 33, &corners, sizeof(corners));
  COLORREF border = 0xFFFFFFFE;
  DwmSetWindowAttribute(window_, 34, &border, sizeof(border));
  BOOL on = TRUE;
  DwmSetWindowAttribute(window_, DWMWA_TRANSITIONS_FORCEDISABLED, &on,
                        sizeof(on));
  DwmSetWindowAttribute(window_, DWMWA_EXCLUDED_FROM_PEEK, &on, sizeof(on));
  SetWindowRgn(window_, CreateRectRgn(0, 0, 0, 0), FALSE);

  Place();
  RECT frame;
  GetClientRect(window_, &frame);
  FlutterDesktopViewControllerProperties properties = {
      frame.right - frame.left, frame.bottom - frame.top};
  controller_ = FlutterDesktopEngineCreateViewController(engine_, &properties);
  if (!controller_) return false;
  FlutterDesktopViewRef view = FlutterDesktopViewControllerGetView(controller_);
  content_ = FlutterDesktopViewGetHWND(view);
  view_id_ = FlutterDesktopViewControllerGetViewId(controller_);
  SetParent(content_, window_);
  MoveWindow(content_, 0, 0, frame.right - frame.left,
             frame.bottom - frame.top, TRUE);

  ShowWindow(window_, SW_SHOWNOACTIVATE);
  SetTimer(window_, kWatchTimer, kWatchMs, nullptr);
  return true;
}

void IslandWindow::Place() {
  if (!window_) return;
  HMONITOR monitor = MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info = {sizeof(info)};
  GetMonitorInfo(monitor, &info);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const int width = static_cast<int>(width_ * scale);
  const int height = static_cast<int>(height_ * scale);
  const RECT& area = info.rcMonitor;
  const LONG top = info.rcWork.top > area.top ? info.rcWork.top : area.top;
  SetWindowPos(window_, HWND_TOPMOST,
               area.left + (area.right - area.left - width) / 2, top, width,
               height, SWP_NOACTIVATE);
}

void IslandWindow::SetSize(int width, int height) {
  if (width < 1 || height < 1) return;
  if (width == width_ && height == height_) return;
  width_ = width;
  height_ = height;
  Place();
}

void IslandWindow::SetShape(const std::vector<POINT>& points) {
  if (!window_) return;
  shape_ = points;
  HRGN region = points.size() < 3
                    ? CreateRectRgn(0, 0, 0, 0)
                    : CreatePolygonRgn(points.data(),
                                       static_cast<int>(points.size()), WINDING);
  SetWindowRgn(window_, region, TRUE);
}

void IslandWindow::TakeKeyboard(bool take) {
  if (!window_ || take == typing_) return;
  typing_ = take;
  if (take) {
    HWND foreground = GetForegroundWindow();
    if (foreground != window_) previous_ = foreground;
    SetForegroundWindow(window_);
    if (content_) SetFocus(content_);
    return;
  }
  HWND previous = previous_;
  previous_ = nullptr;
  if (GetForegroundWindow() == window_ && previous && IsWindow(previous) &&
      IsWindowVisible(previous)) {
    SetForegroundWindow(previous);
  }
}

bool IslandWindow::Blocked() {
  QUERY_USER_NOTIFICATION_STATE state;
  if (SUCCEEDED(SHQueryUserNotificationState(&state)) &&
      (state == QUNS_RUNNING_D3D_FULL_SCREEN ||
       state == QUNS_PRESENTATION_MODE)) {
    return true;
  }
  HWND foreground = GetForegroundWindow();
  if (!foreground || foreground == window_ || !IsWindowVisible(foreground) ||
      IsIconic(foreground) || IsZoomed(foreground) || IsShell(foreground)) {
    return false;
  }
  HMONITOR monitor = MonitorFromWindow(window_, MONITOR_DEFAULTTOPRIMARY);
  if (MonitorFromWindow(foreground, MONITOR_DEFAULTTONULL) != monitor) {
    return false;
  }
  RECT rect;
  if (FAILED(DwmGetWindowAttribute(foreground, DWMWA_EXTENDED_FRAME_BOUNDS,
                                   &rect, sizeof(rect)))) {
    GetWindowRect(foreground, &rect);
  }
  MONITORINFO info = {sizeof(info)};
  GetMonitorInfo(monitor, &info);
  const RECT& area = info.rcMonitor;
  return rect.left <= area.left && rect.top <= area.top &&
         rect.right >= area.right && rect.bottom >= area.bottom;
}

void IslandWindow::Watch() {
  const bool blocked = Blocked();
  if (blocked != hidden_) {
    hidden_ = blocked;
    ShowWindow(window_, blocked ? SW_HIDE : SW_SHOWNOACTIVATE);
    if (notify_) notify_("hidden", blocked);
  }
  if (!hidden_) {
    SetWindowPos(window_, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE |
                     SWP_NOOWNERZORDER);
  }
}

LRESULT CALLBACK IslandWindow::Proc(HWND hwnd, UINT message, WPARAM wparam,
                                    LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto create = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(create->lpCreateParams));
  }
  auto self =
      reinterpret_cast<IslandWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
  if (self && self->window_ == hwnd) {
    return self->Handle(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT IslandWindow::Handle(HWND hwnd, UINT message, WPARAM wparam,
                             LPARAM lparam) {
  if (controller_) {
    LRESULT result;
    if (FlutterDesktopViewControllerHandleTopLevelWindowProc(
            controller_, hwnd, message, wparam, lparam, &result)) {
      return result;
    }
  }
  switch (message) {
    case WM_MOUSEACTIVATE:
      return typing_ ? MA_ACTIVATE : MA_NOACTIVATE;
    case WM_ACTIVATE:
      if (LOWORD(wparam) == WA_INACTIVE && typing_) {
        typing_ = false;
        previous_ = nullptr;
        if (notify_) notify_("typing", false);
      }
      break;
    case WM_CLOSE:
      return 0;
    case WM_SIZE:
      if (content_) {
        MoveWindow(content_, 0, 0, LOWORD(lparam), HIWORD(lparam), TRUE);
      }
      return 0;
    case WM_DPICHANGED:
    case WM_DISPLAYCHANGE:
      Place();
      return 0;
    case WM_SETTINGCHANGE:
      if (wparam == SPI_SETWORKAREA) Place();
      break;
    case WM_TIMER:
      if (wparam == kWatchTimer) {
        Watch();
        return 0;
      }
      break;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}
