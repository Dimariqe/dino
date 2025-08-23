using Dino;
using Dino.Entities;

// Global instance to handle callbacks
namespace Dino.Plugins.WindowsNotification {
    private static SystemTrayIcon? global_tray_instance = null;
    
    // C callback functions that will call the instance methods
    private static void on_tray_left_click() {
        if (global_tray_instance != null) {
            global_tray_instance.on_left_click();
        }
    }
    
    private static void on_tray_menu_click(int item_id) {
        if (global_tray_instance != null) {
            global_tray_instance.on_menu_click(item_id);
        }
    }
}

namespace Dino.Plugins.WindowsNotification {
    public class SystemTrayIcon : GLib.Object {
        private bool tray_active = false;
        private Dino.Application app;
        
        public signal void activated();
        public signal void exit_requested();

        public SystemTrayIcon(Dino.Application app) {
            this.app = app;
            global_tray_instance = this;
            setup_tray();
        }

        private void setup_tray() {
            // Initialize the tray system
            if (!Vapi.SystemTray.init()) {
                GLib.warning("Failed to initialize system tray");
                return;
            }
            
            // Set up callbacks using static functions
            Vapi.SystemTray.set_left_click_callback(on_tray_left_click);
            Vapi.SystemTray.set_menu_callback(on_tray_menu_click);
            
            // Set tooltip
            Vapi.SystemTray.set_tooltip("Dino - XMPP Client");
            
            // Try to set a proper icon
            set_icon_from_resources();
        }

        private void set_icon_from_resources() {
            // Try to find and set the application icon
            string[] icon_paths = {
                "main/dino.ico",
                "main/logo.ico",
                "../dino.ico",
                "../logo.ico",
                "dino.ico",
                "logo.ico"
            };
            
            foreach (string path in icon_paths) {
                var file = GLib.File.new_for_path(path);
                if (file.query_exists()) {
                    if (Vapi.SystemTray.set_icon_from_file(path)) {
                        GLib.debug("Set tray icon from: %s", path);
                        return;
                    }
                }
            }
            
            GLib.warning("Could not find any tray icon file");
        }

        public void show() {
            if (!tray_active) {
                if (Vapi.SystemTray.add()) {
                    tray_active = true;
                    GLib.debug("System tray icon added successfully");
                } else {
                    GLib.warning("Failed to add tray icon");
                }
            } else {
                // If already active, just show it using the new show_tray function
                if (Vapi.SystemTray.show_tray()) {
                    GLib.debug("System tray icon shown successfully");
                } else {
                    GLib.warning("Failed to show tray icon");
                }
            }
        }

        public void hide() {
            if (tray_active) {
                // Use the new hide function that doesn't fully remove the icon
                if (Vapi.SystemTray.hide()) {
                    GLib.debug("System tray icon hidden successfully");
                } else {
                    GLib.warning("Failed to hide tray icon");
                }
            }
        }

        public void set_tooltip(string tooltip) {
            Vapi.SystemTray.set_tooltip(tooltip);
        }

        public void on_left_click() {
            GLib.debug("Tray icon left clicked");
            activated();
        }
        
        public void on_menu_click(int item_id) {
            GLib.debug("Tray menu item clicked: %d", item_id);
            handle_menu_item(item_id);
        }

        private void handle_menu_item(int item_id) {
            switch (item_id) {
                case Vapi.SystemTray.MENU_SHOW:
                    GLib.debug("Show window requested from tray menu");
                    activated();
                    break;
                    
                case Vapi.SystemTray.MENU_EXIT:
                    GLib.debug("Exit requested from tray menu");
                    exit_requested();
                    break;
                    
                default:
                    GLib.warning("Unknown menu item: %d", item_id);
                    break;
            }
        }

        ~SystemTrayIcon() {
            hide();
            if (global_tray_instance == this) {
                global_tray_instance = null;
            }
        }
    }
}
