#include "video_scene.h"

#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <gst/video/video.h>

#include <algorithm>
#include <cstring>
#include <map>
#include <vector>

G_DECLARE_FINAL_TYPE(SceneTexture, scene_texture, SCENE, TEXTURE,
                     FlPixelBufferTexture)

struct _SceneTexture {
  FlPixelBufferTexture parent_instance;
  GMutex mutex;
  std::vector<uint8_t>* front;
  std::vector<uint8_t>* back;
  bool fresh;
  uint32_t width;
  uint32_t height;
};

G_DEFINE_TYPE(SceneTexture, scene_texture, fl_pixel_buffer_texture_get_type())

static gboolean scene_texture_copy_pixels(FlPixelBufferTexture* texture,
                                          const uint8_t** out_buffer,
                                          uint32_t* width, uint32_t* height,
                                          GError** error) {
  SceneTexture* self = SCENE_TEXTURE(texture);
  g_mutex_lock(&self->mutex);
  if (self->fresh) {
    std::swap(self->front, self->back);
    self->fresh = false;
  }
  *out_buffer = self->front->data();
  *width = self->width;
  *height = self->height;
  g_mutex_unlock(&self->mutex);
  return TRUE;
}

static void scene_texture_finalize(GObject* object) {
  SceneTexture* self = SCENE_TEXTURE(object);
  delete self->front;
  delete self->back;
  g_mutex_clear(&self->mutex);
  G_OBJECT_CLASS(scene_texture_parent_class)->finalize(object);
}

static void scene_texture_class_init(SceneTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels =
      scene_texture_copy_pixels;
  G_OBJECT_CLASS(klass)->finalize = scene_texture_finalize;
}

static void scene_texture_init(SceneTexture* self) {
  g_mutex_init(&self->mutex);
  self->front = new std::vector<uint8_t>();
  self->back = new std::vector<uint8_t>();
  self->fresh = false;
  self->width = 0;
  self->height = 0;
}

static void scene_texture_store(SceneTexture* self, GstSample* sample) {
  GstCaps* caps = gst_sample_get_caps(sample);
  GstBuffer* buffer = gst_sample_get_buffer(sample);
  GstVideoInfo info;
  if (caps == nullptr || buffer == nullptr ||
      !gst_video_info_from_caps(&info, caps)) {
    return;
  }
  GstVideoFrame frame;
  if (!gst_video_frame_map(&frame, &info, buffer, GST_MAP_READ)) {
    return;
  }
  const uint32_t width = GST_VIDEO_FRAME_WIDTH(&frame);
  const uint32_t height = GST_VIDEO_FRAME_HEIGHT(&frame);
  const size_t row = static_cast<size_t>(width) * 4;
  const size_t stride = GST_VIDEO_FRAME_PLANE_STRIDE(&frame, 0);
  const uint8_t* source =
      static_cast<const uint8_t*>(GST_VIDEO_FRAME_PLANE_DATA(&frame, 0));
  g_mutex_lock(&self->mutex);
  self->back->resize(row * height);
  for (uint32_t y = 0; y < height; y++) {
    memcpy(self->back->data() + y * row, source + y * stride, row);
  }
  self->width = width;
  self->height = height;
  self->fresh = true;
  g_mutex_unlock(&self->mutex);
  gst_video_frame_unmap(&frame);
}

struct Scene {
  int64_t id;
  GstElement* pipeline;
  SceneTexture* texture;
  guint bus_watch;
};

static FlTextureRegistrar* registrar = nullptr;
static FlMethodChannel* channel = nullptr;
static std::map<int64_t, Scene*> scenes;

static gboolean mark_frame(gpointer data) {
  const int64_t id = static_cast<int64_t>(reinterpret_cast<intptr_t>(data));
  auto found = scenes.find(id);
  if (found != scenes.end()) {
    fl_texture_registrar_mark_texture_frame_available(
        registrar, FL_TEXTURE(found->second->texture));
  }
  return G_SOURCE_REMOVE;
}

static GstFlowReturn on_new_sample(GstAppSink* sink, gpointer user_data) {
  Scene* scene = static_cast<Scene*>(user_data);
  GstSample* sample = gst_app_sink_pull_sample(sink);
  if (sample == nullptr) {
    return GST_FLOW_OK;
  }
  scene_texture_store(scene->texture, sample);
  gst_sample_unref(sample);
  g_idle_add(mark_frame,
             reinterpret_cast<gpointer>(static_cast<intptr_t>(scene->id)));
  return GST_FLOW_OK;
}

static gboolean on_bus_message(GstBus* bus, GstMessage* message,
                               gpointer user_data) {
  Scene* scene = static_cast<Scene*>(user_data);
  if (GST_MESSAGE_TYPE(message) == GST_MESSAGE_EOS) {
    gst_element_seek_simple(
        scene->pipeline, GST_FORMAT_TIME,
        static_cast<GstSeekFlags>(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT),
        0);
  }
  return TRUE;
}

static void close_scene(Scene* scene) {
  gst_element_set_state(scene->pipeline, GST_STATE_NULL);
  g_source_remove(scene->bus_watch);
  scenes.erase(scene->id);
  fl_texture_registrar_unregister_texture(registrar,
                                          FL_TEXTURE(scene->texture));
  gst_object_unref(scene->pipeline);
  g_object_unref(scene->texture);
  delete scene;
}

static FlMethodResponse* scene_error(const gchar* message) {
  return FL_METHOD_RESPONSE(
      fl_method_error_response_new("scene", message, nullptr));
}

static FlMethodResponse* open_scene(const gchar* path) {
  g_autofree gchar* description = g_strdup_printf(
      "filesrc location=\"%s\" ! decodebin ! videoconvert ! "
      "video/x-raw,format=RGBA ! "
      "appsink name=sink sync=true max-buffers=2 drop=true",
      path);
  GError* error = nullptr;
  GstElement* pipeline = gst_parse_launch(description, &error);
  if (pipeline == nullptr) {
    FlMethodResponse* response = scene_error(error->message);
    g_error_free(error);
    return response;
  }
  if (error != nullptr) {
    g_error_free(error);
  }
  GstElement* sink = gst_bin_get_by_name(GST_BIN(pipeline), "sink");
  gst_element_set_state(pipeline, GST_STATE_PAUSED);
  GstSample* preroll = nullptr;
  if (gst_element_get_state(pipeline, nullptr, nullptr, 5 * GST_SECOND) !=
      GST_STATE_CHANGE_FAILURE) {
    preroll =
        gst_app_sink_try_pull_preroll(GST_APP_SINK(sink), 5 * GST_SECOND);
  }
  if (preroll == nullptr) {
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(sink);
    gst_object_unref(pipeline);
    return scene_error("Could not decode the video");
  }

  Scene* scene = new Scene();
  scene->pipeline = pipeline;
  scene->texture =
      SCENE_TEXTURE(g_object_new(scene_texture_get_type(), nullptr));
  scene_texture_store(scene->texture, preroll);
  gst_sample_unref(preroll);
  fl_texture_registrar_register_texture(registrar,
                                        FL_TEXTURE(scene->texture));
  scene->id = fl_texture_get_id(FL_TEXTURE(scene->texture));
  scenes[scene->id] = scene;

  GstAppSinkCallbacks callbacks = {};
  callbacks.new_sample = on_new_sample;
  gst_app_sink_set_callbacks(GST_APP_SINK(sink), &callbacks, scene, nullptr);
  gst_object_unref(sink);

  GstBus* bus = gst_element_get_bus(pipeline);
  scene->bus_watch = gst_bus_add_watch(bus, on_bus_message, scene);
  gst_object_unref(bus);

  gst_element_set_state(pipeline, GST_STATE_PLAYING);

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "id", fl_value_new_int(scene->id));
  fl_value_set_string_take(result, "width",
                           fl_value_new_int(scene->texture->width));
  fl_value_set_string_take(result, "height",
                           fl_value_new_int(scene->texture->height));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void on_method_call(FlMethodChannel* channel, FlMethodCall* call,
                           gpointer user_data) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(method, "open") == 0) {
    FlValue* path = fl_value_lookup_string(args, "path");
    response = path == nullptr ? scene_error("No path")
                               : open_scene(fl_value_get_string(path));
  } else if (g_strcmp0(method, "close") == 0) {
    FlValue* id = fl_value_lookup_string(args, "id");
    auto found = scenes.find(id == nullptr ? 0 : fl_value_get_int(id));
    if (found != scenes.end()) {
      close_scene(found->second);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

void video_scene_register(FlView* view) {
  gst_init(nullptr, nullptr);
  FlEngine* engine = fl_view_get_engine(view);
  registrar = fl_engine_get_texture_registrar(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine),
                                  "streak/video_scene",
                                  FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, on_method_call, nullptr,
                                            nullptr);
}
