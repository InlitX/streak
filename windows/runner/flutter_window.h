#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

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

  flutter::DartProject project_;

  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;
  bool fullscreen_ = false;
  bool maximized_ = false;
  LONG windowed_style_ = 0;
  WINDOWPLACEMENT windowed_placement_ = {sizeof(WINDOWPLACEMENT)};
};

#endif
