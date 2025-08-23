using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
    public class Plugin : RootInterface, Object {

        private static string AUMID = "org.dino.Dino";
        private SystemTrayIcon? tray_icon = null;
        private Dino.Entities.Settings settings;
        private Dino.Application app;

        public void registered(Dino.Application app) {
            this.app = app;
            this.settings = app.settings;

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

            // Initialize system tray based on current setting
            update_tray_visibility();
            settings.notify["minimize-to-tray"].connect(() => {
                update_tray_visibility();
            });
        }

        private void update_tray_visibility() {
            // Create tray icon instance only once if it doesn't exist
            if (tray_icon == null) {
                tray_icon = new SystemTrayIcon(app);
                
                // Connect tray icon signals
                tray_icon.activated.connect(() => {
                    debug("Tray icon activated - showing window");
                    app.activate();
                });
                
                tray_icon.exit_requested.connect(() => {
                    debug("Exit requested from tray - quitting application");
                    app.quit();
                });
            }
            
            // Show or hide the tray icon based on setting
            if (settings.minimize_to_tray) {
                tray_icon.show();
            } else {
                tray_icon.hide();
            }
        }

        public void shutdown() {
            if (tray_icon != null) {
                tray_icon.hide();
                // Don't set to null here - let GC handle it naturally
            }
        }
    }
}
