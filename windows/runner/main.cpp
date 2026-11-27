#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  ::CreateMutexW(nullptr, TRUE, L"StreakSingleInstance");
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND running = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Streak");
    if (running) {
      if (!::IsWindowVisible(running)) {
        ::PostMessageW(running, kShowFromTray, 0, 0);
        return EXIT_SUCCESS;
      }
      if (::IsIconic(running)) ::ShowWindow(running, SW_RESTORE);
      if (!::IsZoomed(running)) {
        RECT frame;
        MONITORINFO monitor = {sizeof(monitor)};
        ::GetWindowRect(running, &frame);
        ::GetMonitorInfo(
            ::MonitorFromWindow(running, MONITOR_DEFAULTTONEAREST), &monitor);
        const RECT& area = monitor.rcWork;
        const LONG width = frame.right - frame.left;
        const LONG height = frame.bottom - frame.top;
        ::SetWindowPos(running, nullptr,
                       (std::max)(area.left,
                                  area.left + (area.right - area.left - width) / 2),
                       (std::max)(area.top,
                                  area.top + (area.bottom - area.top - height) / 2),
                       0, 0,
                       SWP_NOSIZE | SWP_NOZORDER);
      }
      ::SetForegroundWindow(running);
    }
    return EXIT_SUCCESS;
  }

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1500, 920);
  if (!window.Create(L"Streak", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
