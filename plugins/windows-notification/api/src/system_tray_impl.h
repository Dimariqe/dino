#ifndef SYSTEM_TRAY_IMPL_H
#define SYSTEM_TRAY_IMPL_H

#include <glib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Menu item IDs
#define ID_TRAY_SHOW 1001
#define ID_TRAY_EXIT 1002

// Callback function types
typedef void (*tray_callback_t)(void);
typedef void (*menu_callback_t)(int item_id);

// Function declarations
gboolean tray_init(void);
gboolean tray_add(void);
gboolean tray_remove(void);
gboolean tray_set_tooltip(const char* tooltip);
gboolean tray_set_icon_from_file(const char* icon_path);
void tray_set_left_click_callback(tray_callback_t callback);
void tray_set_menu_callback(menu_callback_t callback);

#ifdef __cplusplus
}
#endif

#endif // SYSTEM_TRAY_IMPL_H
