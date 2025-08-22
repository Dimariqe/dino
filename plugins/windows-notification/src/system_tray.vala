using Dino.Plugins.WindowsNotification.Vapi;

namespace Dino.Plugins.WindowsNotification {
    public class SystemTrayIcon : Object {
        private bool tray_active = false;
        private Dino.Application app;
        
        public signal void activated();
        public signal void exit_requested();

        public SystemTrayIcon(Dino.Application app) {
            this.app = app;
            setup_tray();
        }

        private void setup_tray() {
            // Initialize the tray system
            if (!SystemTray.init()) {
                warning("Failed to initialize system tray");
                return;
            }
            
            // Set up callbacks
            SystemTray.set_left_click_callback(() => {
                debug("Tray icon left clicked");
                activated();
            });
            
            SystemTray.set_menu_callback((item_id) => {
                debug("Tray menu item clicked: %d", item_id);
                handle_menu_item(item_id);
            });
            
            // Set tooltip
            SystemTray.set_tooltip("Dino - XMPP Client");
            
            // Try to set a proper icon
            set_icon_from_resources();
        }

        private void set_icon_from_resources() {
            // Try to find and set the application icon
            string[] icon_paths = {
                "/dino/icons/scalable/apps/im.dino.Dino.svg",
                "/dino/icons/hicolor/scalable/apps/im.dino.Dino.svg", 
                "/usr/share/icons/hicolor/16x16/apps/im.dino.Dino.png",
                "/usr/share/icons/hicolor/32x32/apps/im.dino.Dino.png",
                "./main/dino.ico",
                "./dino.ico"
            };
            
            foreach (string path in icon_paths) {
                var file = File.new_for_path(path);
                if (file.query_exists()) {
                    if (SystemTray.set_icon_from_file(path)) {
                        debug("Set tray icon from: %s", path);
                        break;
                    }
                }
            }
        }

        public void show() {
            if (!tray_active) {
                if (SystemTray.add()) {
                    tray_active = true;
                    debug("System tray icon added successfully");
                } else {
                    warning("Failed to add tray icon");
                }
            }
        }

        public void hide() {
            if (tray_active) {
                if (SystemTray.remove()) {
                    tray_active = false;
                    debug("System tray icon removed successfully");
                } else {
                    warning("Failed to remove tray icon");
                }
            }
        }

        public void set_tooltip(string tooltip) {
            SystemTray.set_tooltip(tooltip);
        }

        private void handle_menu_item(int item_id) {
            switch (item_id) {
                case SystemTray.MENU_SHOW:
                    debug("Show window requested from tray menu");
                    activated();
                    break;
                    
                case SystemTray.MENU_EXIT:
                    debug("Exit requested from tray menu");
                    exit_requested();
                    break;
                    
                default:
                    warning("Unknown menu item: %d", item_id);
                    break;
            }
        }

        ~SystemTrayIcon() {
            hide();
        }
    }
}
