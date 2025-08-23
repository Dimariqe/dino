using Dino;
using Dino.Entities;

namespace Dino.Plugins.WindowsNotification {
    public class SystemTrayPlugin : RootInterface, Object {
        private SystemTrayIcon? tray_icon = null;
        private Dino.Application app;
        private Dino.Entities.Settings settings;

        public void registered(Dino.Application app) {
            print("SystemTrayPlugin: Plugin registered!\n");
            this.app = app;
            this.settings = app.settings;
            
            print("SystemTrayPlugin: Initial minimize_to_tray setting: %s\n", settings.minimize_to_tray.to_string());
            
            // Create tray icon
            tray_icon = new SystemTrayIcon(app);
            
            // Connect signals
            tray_icon.activated.connect(() => {
                // Show/restore main window when tray icon is clicked
                app.activate();
            });
            
            tray_icon.exit_requested.connect(() => {
                // Quit application when exit is requested from tray menu
                app.quit();
            });
            
            // Monitor the minimize_to_tray setting and show/hide tray accordingly
            update_tray_visibility();
            settings.notify["minimize-to-tray"].connect(() => {
                print("SystemTrayPlugin: minimize_to_tray setting changed to: %s\n", settings.minimize_to_tray.to_string());
                update_tray_visibility();
            });
        }

        private void update_tray_visibility() {
            if (tray_icon == null) return;
            
            print("SystemTrayPlugin: Updating tray visibility, minimize_to_tray = %s\n", settings.minimize_to_tray.to_string());
            
            if (settings.minimize_to_tray) {
                tray_icon.show();
                print("SystemTrayPlugin: Tray icon shown\n");
            } else {
                tray_icon.hide();
                print("SystemTrayPlugin: Tray icon hidden\n");
            }
        }

        public void shutdown() {
            if (tray_icon != null) {
                tray_icon.hide();
                tray_icon = null;
            }
        }
    }
}
