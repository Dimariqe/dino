using Dino;
using Dino.Entities;

namespace Dino.Plugins.WindowsNotification {
    public class SystemTrayPlugin : RootInterface, Object {
        private SystemTrayIcon? tray_icon = null;
        private Dino.Application app;

        public void registered(Dino.Application app) {
            this.app = app;
            
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
            
            // Show tray icon
            tray_icon.show();
        }

        public void shutdown() {
            if (tray_icon != null) {
                tray_icon.hide();
                tray_icon = null;
            }
        }
    }
}
