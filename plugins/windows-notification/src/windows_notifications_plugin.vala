using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
    public class Plugin : RootInterface, Object {

        private static string AUMID = "org.dino.Dino";
        private SystemTrayIcon? tray_icon = null;

        public void registered(Dino.Application app) {

            if (!winrt.InitApartment())
            {
                // log error, return
            }

            if (!Win32Api.SetProcessAumid(AUMID))
            {
                // log error, return
            }

            if (!ShortcutCreator.EnsureAumiddedShortcutExists(AUMID))
            {
                // log error, return
            }

            app.stream_interactor.get_module(NotificationEvents.IDENTITY)
                .register_notification_provider(new WindowsNotificationProvider(app, new ToastNotifier(AUMID)));

            // Initialize system tray
            tray_icon = new SystemTrayIcon(app);
            
            // Connect tray icon signals
            tray_icon.activated.connect(() => {
                // Show/restore main window when tray icon is clicked
                debug("Tray icon activated - showing window");
                app.activate();
            });
            
            tray_icon.exit_requested.connect(() => {
                // Exit application when exit is requested from tray menu
                debug("Exit requested from tray - quitting application");
                app.quit();
            });
            
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
