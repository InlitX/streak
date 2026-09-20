cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "video_scene.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET
  gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0)

target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GSTREAMER)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
