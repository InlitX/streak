#ifndef RUNNER_ISLAND_WINDOW_H_
#define RUNNER_ISLAND_WINDOW_H_

#include <flutter_windows.h>
#include <windows.h>

#include <cstdint>
#include <functional>
#include <vector>

extern "C" {
typedef struct {
  int width;
  int height;
} FlutterDesktopViewControllerProperties;

FLUTTER_EXPORT FlutterDesktopViewControllerRef
FlutterDesktopEngineCreateViewController(
    FlutterDesktopEngineRef engine,
    const FlutterDesktopViewControllerProperties* properties);

FLUTTER_EXPORT FlutterDesktopEngineRef FlutterDesktopEngineForId(
    int64_t engine_id);
}

class IslandWindow {
 public:
  IslandWindow(FlutterDesktopEngineRef engine,
               std::function<void(const char*, bool)> notify);
  ~IslandWindow();

  bool Create();
  int64_t view_id() const { return view_id_; }
  void SetShape(const std::vector<POINT>& points);
  void TakeKeyboard(bool take);
  void SetSize(int width, int height);

 private:
  static LRESULT CALLBACK Proc(HWND hwnd, UINT message, WPARAM wparam,
                               LPARAM lparam);
  LRESULT Handle(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
  void Place();
  void Watch();
  bool Blocked();

  FlutterDesktopEngineRef engine_;
  FlutterDesktopViewControllerRef controller_ = nullptr;
  std::function<void(const char*, bool)> notify_;
  HWND window_ = nullptr;
  HWND content_ = nullptr;
  HWND previous_ = nullptr;
  int64_t view_id_ = -1;
  int width_ = 680;
  int height_ = 460;
  bool typing_ = false;
  bool hidden_ = false;
  std::vector<POINT> shape_;
};

#endif
