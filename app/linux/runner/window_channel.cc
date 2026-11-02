#include "window_channel.h"

struct WindowState {
  GtkWindow* window;
  FlMethodChannel* channel;
  gboolean close_confirmed;
};

static gboolean on_delete_event(GtkWidget* widget, GdkEvent* event,
                                gpointer user_data) {
  WindowState* state = static_cast<WindowState*>(user_data);
  if (state->close_confirmed) {
    return FALSE;
  }
  fl_method_channel_invoke_method(state->channel, "closeRequested", nullptr,
                                  nullptr, nullptr, nullptr);
  return TRUE;
}

static void pointer_position(GtkWindow* window, gint* x, gint* y) {
  GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
  GdkSeat* seat = gdk_display_get_default_seat(display);
  GdkDevice* pointer = gdk_seat_get_pointer(seat);
  gdk_device_get_position(pointer, nullptr, x, y);
}

static void respond_bad_arguments(FlMethodCall* call) {
  fl_method_call_respond_error(call, "bad-arguments",
                               "The argument has the wrong type.", nullptr,
                               nullptr);
}

static void handle_call(FlMethodChannel* channel, FlMethodCall* call,
                        gpointer user_data) {
  WindowState* state = static_cast<WindowState*>(user_data);
  GtkWindow* window = state->window;
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);

  if (g_strcmp0(method, "startMove") == 0) {
    gint x = 0;
    gint y = 0;
    pointer_position(window, &x, &y);
    gtk_window_begin_move_drag(window, 1, x, y, GDK_CURRENT_TIME);
  } else if (g_strcmp0(method, "startResize") == 0) {
    if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_INT) {
      respond_bad_arguments(call);
      return;
    }
    gint x = 0;
    gint y = 0;
    pointer_position(window, &x, &y);
    gtk_window_begin_resize_drag(
        window, static_cast<GdkWindowEdge>(fl_value_get_int(args)), 1, x, y,
        GDK_CURRENT_TIME);
  } else if (g_strcmp0(method, "minimize") == 0) {
    gtk_window_iconify(window);
  } else if (g_strcmp0(method, "toggleMaximize") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
  } else if (g_strcmp0(method, "close") == 0) {
    gtk_window_close(window);
  } else if (g_strcmp0(method, "forceClose") == 0) {
    state->close_confirmed = TRUE;
    gtk_window_close(window);
  } else if (g_strcmp0(method, "setTitle") == 0) {
    if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
      respond_bad_arguments(call);
      return;
    }
    gtk_window_set_title(window, fl_value_get_string(args));
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  fl_method_call_respond_success(call, nullptr, nullptr);
}

FlMethodChannel* window_channel_new(FlView* view, GtkWindow* window) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "mauna_ranga/window", FL_METHOD_CODEC(codec));
  WindowState* state = g_new0(WindowState, 1);
  state->window = window;
  state->channel = channel;
  g_signal_connect(window, "delete-event", G_CALLBACK(on_delete_event), state);
  fl_method_channel_set_method_call_handler(channel, handle_call, state,
                                            g_free);
  return channel;
}
