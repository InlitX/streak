#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "island_window.h"
#include "win32_window.h"

constexpr UINT kShowFromTray = WM_APP + 2;

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetFullscreen(bool on);
  void RestorePlacement();
  void SavePlacement();
  void Reveal();
  void Refit();
  void HandleIsland(const flutter::MethodCall<flutter::EncodableValue>& call,
                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void BringToFront();
  void SetTray(const flutter::EncodableValue* args);
  void HideToTray();
  void ShowFromTray();
  void AddTrayIcon();
  void RemoveTrayIcon();
  void ShowTrayMenu();

  flutter::DartProject project_;

  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      island_channel_;
  std::unique_ptr<IslandWindow> island_;
  bool tray_enabled_ = false;
  bool in_tray_ = false;
  std::wstring tray_open_ = L"Open Streak";
  std::wstring tray_quit_ = L"Quit";
  UINT taskbar_created_ = RegisterWindowMessageW(L"TaskbarCreated");
  bool fullscreen_ = false;
  bool maximized_ = false;
  LONG windowed_style_ = 0;
  WINDOWPLACEMENT windowed_placement_ = {sizeof(WINDOWPLACEMENT)};
};

#endif
