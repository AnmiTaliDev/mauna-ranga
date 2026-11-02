#ifndef RUNNER_WINDOW_CHANNEL_H_
#define RUNNER_WINDOW_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

FlMethodChannel* window_channel_new(FlView* view, GtkWindow* window);

#endif  // RUNNER_WINDOW_CHANNEL_H_
