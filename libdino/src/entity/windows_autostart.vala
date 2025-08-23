using GLib;

namespace Dino.Entities {

#if _WIN32
    public class WindowsAutostart {
        private const string REGISTRY_KEY = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
        private const string APP_NAME = "Dino";

        public static bool set_autostart(bool enabled) {
            if (enabled) {
                return add_to_startup();
            } else {
                return remove_from_startup();
            }
        }

        public static bool get_autostart_status() {
            var command = @"reg query \"$REGISTRY_KEY\" /v \"$APP_NAME\" 2>nul";
            try {
                string output;
                int exit_status;
                GLib.Process.spawn_command_line_sync(command, out output, null, out exit_status);
                return exit_status == 0 && output.contains(APP_NAME);
            } catch (Error e) {
                return false;
            }
        }

        private static bool add_to_startup() {
            var app_path = get_application_path();
            if (app_path == null) {
                warning("Could not determine application path for autostart");
                return false;
            }

            var command = @"reg add \"$REGISTRY_KEY\" /v \"$APP_NAME\" /t REG_SZ /d \"\\\"$app_path\\\"\" /f";
            try {
                string error_output;
                int exit_status;
                GLib.Process.spawn_command_line_sync(command, null, out error_output, out exit_status);
                if (exit_status != 0) {
                    warning("Failed to add autostart entry: %s", error_output);
                    return false;
                }
                return true;
            } catch (Error e) {
                warning("Failed to add autostart entry: %s", e.message);
                return false;
            }
        }

        private static bool remove_from_startup() {
            var command = @"reg delete \"$REGISTRY_KEY\" /v \"$APP_NAME\" /f";
            try {
                int exit_status;
                GLib.Process.spawn_command_line_sync(command, null, null, out exit_status);
                // Return true even if entry doesn't exist (exit_status != 0)
                return true;
            } catch (Error e) {
                warning("Failed to remove autostart entry: %s", e.message);
                return false;
            }
        }

        private static string? get_application_path() {
            // Try to get path from environment (for portable apps)
            var app_path = GLib.Environment.get_variable("APPIMAGE");
            if (app_path != null) {
                return app_path;
            }

            // Try to get the executable path
            try {
                app_path = GLib.FileUtils.read_link("/proc/self/exe");
                if (app_path != null) {
                    return app_path;
                }
            } catch (Error e) {
                // /proc/self/exe might not work on Windows, try alternative
            }

            // Fallback to program name from command line
            var prgname = GLib.Environment.get_prgname();
            if (prgname != null && GLib.Path.is_absolute(prgname)) {
                return prgname;
            }

            // Final fallback - try to find executable in current directory
            var exe_name = "dino.exe";
            if (GLib.FileUtils.test(exe_name, GLib.FileTest.IS_EXECUTABLE)) {
                try {
                    return GLib.Environment.get_current_dir() + "\\" + exe_name;
                } catch (Error e) {
                    return null;
                }
            }

            return null;
        }
    }
#endif

}
