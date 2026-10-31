#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "video_scene.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* window_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static const int kDefaultWidth = 1500;
static const int kDefaultHeight = 920;
static const int kMinWidth = 360;
static const int kMinHeight = 560;

static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void window_method_call(FlMethodChannel* channel, FlMethodCall* call,
                               gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(fl_method_call_get_name(call), "fullscreen") == 0 &&
      fl_value_get_type(args) == FL_VALUE_TYPE_BOOL) {
    if (fl_value_get_bool(args)) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

static void set_window_icon(GtkWindow* window) {
  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) {
    return;
  }
  g_autofree gchar* directory = g_path_get_dirname(executable);
  g_autofree gchar* icon = g_build_filename(
      directory, "data", "flutter_assets", "assets", "icon.png", nullptr);
  gtk_window_set_icon_from_file(window, icon, nullptr);
}

static gchar* window_state_path() {
  return g_build_filename(g_get_user_config_dir(), "streak", "window.ini",
                          nullptr);
}

static gboolean window_delete_cb(GtkWidget* widget, GdkEvent* event,
                                 gpointer user_data) {
  GdkWindow* surface = gtk_widget_get_window(widget);
  if (surface != nullptr &&
      (gdk_window_get_state(surface) & GDK_WINDOW_STATE_FULLSCREEN)) {
    return FALSE;
  }
  GtkWindow* window = GTK_WINDOW(widget);
  g_autofree gchar* path = window_state_path();
  g_autofree gchar* directory = g_path_get_dirname(path);
  g_autoptr(GKeyFile) file = g_key_file_new();
  g_key_file_load_from_file(file, path, G_KEY_FILE_NONE, nullptr);
  const gboolean maximized = gtk_window_is_maximized(window);
  g_key_file_set_boolean(file, "window", "maximized", maximized);
  if (!maximized) {
    int width = 0;
    int height = 0;
    gtk_window_get_size(window, &width, &height);
    g_key_file_set_integer(file, "window", "width", width);
    g_key_file_set_integer(file, "window", "height", height);
  }
  g_mkdir_with_parents(directory, 0700);
  g_key_file_save_to_file(file, path, nullptr);
  return FALSE;
}

static void size_window(GtkWindow* window) {
  int width = kDefaultWidth;
  int height = kDefaultHeight;
  g_autofree gchar* path = window_state_path();
  g_autoptr(GKeyFile) file = g_key_file_new();
  if (g_key_file_load_from_file(file, path, G_KEY_FILE_NONE, nullptr)) {
    const int saved_width =
        g_key_file_get_integer(file, "window", "width", nullptr);
    const int saved_height =
        g_key_file_get_integer(file, "window", "height", nullptr);
    if (saved_width >= kMinWidth && saved_height >= kMinHeight) {
      width = saved_width;
      height = saved_height;
    }
    if (g_key_file_get_boolean(file, "window", "maximized", nullptr)) {
      gtk_window_maximize(window);
    }
  }
  g_signal_connect(window, "delete-event", G_CALLBACK(window_delete_cb),
                   nullptr);
  GdkDisplay* display = gdk_display_get_default();
  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  if (monitor == nullptr && gdk_display_get_n_monitors(display) > 0) {
    monitor = gdk_display_get_monitor(display, 0);
  }
  if (monitor != nullptr) {
    GdkRectangle area;
    gdk_monitor_get_workarea(monitor, &area);
    width = MIN(width, area.width);
    height = MIN(height, area.height);
  }
  gtk_window_set_default_size(window, width, height);
  gtk_widget_set_size_request(GTK_WIDGET(window), kMinWidth, kMinHeight);
}

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GList* open = gtk_application_get_windows(GTK_APPLICATION(application));
  if (open != nullptr) {
    gtk_window_present(GTK_WINDOW(open->data));
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Streak");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Streak");
  }

  set_window_icon(window);
  size_window(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  video_scene_register(view);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "streak/window", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->window_channel, window_method_call, window, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     static_cast<GApplicationFlags>(0),
                                     nullptr));
}
