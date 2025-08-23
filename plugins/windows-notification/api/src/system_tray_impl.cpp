#include <windows.h>
#include <shellapi.h>
#include <glib.h>

// Callback function pointer types
typedef void (*tray_callback_t)(void);
typedef void (*menu_callback_t)(int item_id);

// Global variables
static HWND g_hidden_window = NULL;
static NOTIFYICONDATAW g_nid = {0};
static tray_callback_t g_left_click_callback = NULL;
static menu_callback_t g_menu_callback = NULL;
static HMENU g_popup_menu = NULL;

// Window message constants
#define WM_TRAYICON (WM_USER + 1)
#define ID_TRAY_SHOW 1001
#define ID_TRAY_EXIT 1002

// Window procedure for hidden window
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_TRAYICON:
            switch (LOWORD(lParam)) {
                case WM_LBUTTONUP:
                    // Left click - show window
                    if (g_left_click_callback) {
                        g_left_click_callback();
                    }
                    break;
                    
                case WM_RBUTTONUP:
                    // Right click - show context menu
                    if (g_popup_menu) {
                        POINT cursor_pos;
                        GetCursorPos(&cursor_pos);
                        
                        // Required for popup menu to work correctly
                        SetForegroundWindow(hwnd);
                        
                        int cmd = TrackPopupMenu(
                            g_popup_menu,
                            TPM_RETURNCMD | TPM_NONOTIFY,
                            cursor_pos.x,
                            cursor_pos.y,
                            0,
                            hwnd,
                            NULL
                        );
                        
                        if (cmd > 0 && g_menu_callback) {
                            g_menu_callback(cmd);
                        }
                        
                        // Required cleanup
                        PostMessage(hwnd, WM_NULL, 0, 0);
                    }
                    break;
            }
            break;
            
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
            
        default:
            return DefWindowProcW(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}

// Initialize system tray
extern "C" {

gboolean tray_init(void) {
    // Register window class
    WNDCLASSW wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandleW(NULL);
    wc.lpszClassName = L"DinoTrayWindow";
    
    if (!RegisterClassW(&wc)) {
        return FALSE;
    }
    
    // Create hidden window
    g_hidden_window = CreateWindowW(
        L"DinoTrayWindow",
        L"Dino Tray",
        0, 0, 0, 0, 0,
        NULL, NULL,
        GetModuleHandleW(NULL),
        NULL
    );
    
    if (!g_hidden_window) {
        return FALSE;
    }
    
    // Initialize NOTIFYICONDATA
    ZeroMemory(&g_nid, sizeof(g_nid));
    g_nid.cbSize = sizeof(g_nid);
    g_nid.hWnd = g_hidden_window;
    g_nid.uID = 1;
    g_nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;
    
    // Load default icon (we'll replace this with a proper icon later)
    g_nid.hIcon = LoadIconW(NULL, MAKEINTRESOURCEW(32512)); // IDI_APPLICATION
    wcscpy_s(g_nid.szTip, L"Dino - XMPP Client");
    
    // Create popup menu
    g_popup_menu = CreatePopupMenu();
    AppendMenuW(g_popup_menu, MF_STRING, ID_TRAY_SHOW, L"Show Dino");
    AppendMenuW(g_popup_menu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(g_popup_menu, MF_STRING, ID_TRAY_EXIT, L"Exit");
    
    return TRUE;
}

gboolean tray_add(void) {
    return Shell_NotifyIconW(NIM_ADD, &g_nid);
}

gboolean tray_remove(void) {
    if (g_popup_menu) {
        DestroyMenu(g_popup_menu);
        g_popup_menu = NULL;
    }
    
    gboolean result = Shell_NotifyIconW(NIM_DELETE, &g_nid);
    
    if (g_hidden_window) {
        DestroyWindow(g_hidden_window);
        g_hidden_window = NULL;
    }
    
    return result;
}

gboolean tray_hide(void) {
    if (g_nid.hWnd) {
        // Use NIM_DELETE to hide the icon temporarily
        return Shell_NotifyIconW(NIM_DELETE, &g_nid);
    }
    return FALSE;
}

gboolean tray_show(void) {
    if (g_nid.hWnd) {
        // Re-add the icon to show it
        return Shell_NotifyIconW(NIM_ADD, &g_nid);
    }
    return FALSE;
}

gboolean tray_set_tooltip(const char* tooltip) {
    if (!tooltip) return FALSE;
    
    // Convert UTF-8 to UTF-16
    glong items_written;
    gunichar2* utf16_text = g_utf8_to_utf16(tooltip, -1, NULL, &items_written, NULL);
    
    if (utf16_text && items_written < 128) {
        wcscpy_s(g_nid.szTip, (const wchar_t*)utf16_text);
        g_free(utf16_text);
        
        if (g_nid.hWnd) {
            return Shell_NotifyIconW(NIM_MODIFY, &g_nid);
        }
    }
    
    if (utf16_text) g_free(utf16_text);
    return FALSE;
}

gboolean tray_set_icon_from_file(const char* icon_path) {
    if (!icon_path) return FALSE;
    
    g_print("Trying to load icon from: %s\n", icon_path);
    
    // Convert UTF-8 to UTF-16 for Windows API
    glong items_written;
    gunichar2* utf16_path = g_utf8_to_utf16(icon_path, -1, NULL, &items_written, NULL);
    
    if (utf16_path) {
        // Try loading with different sizes and flags
        HICON new_icon = (HICON)LoadImageW(
            NULL,
            (const wchar_t*)utf16_path,
            IMAGE_ICON,
            0, 0,  // Use default icon size
            LR_LOADFROMFILE | LR_DEFAULTSIZE
        );
        
        if (!new_icon) {
            // Try with 16x16 size
            new_icon = (HICON)LoadImageW(
                NULL,
                (const wchar_t*)utf16_path,
                IMAGE_ICON,
                16, 16,
                LR_LOADFROMFILE
            );
        }
        
        if (!new_icon) {
            // Try with 32x32 size
            new_icon = (HICON)LoadImageW(
                NULL,
                (const wchar_t*)utf16_path,
                IMAGE_ICON,
                32, 32,
                LR_LOADFROMFILE
            );
        }
        
        g_free(utf16_path);
        
        if (new_icon) {
            g_print("Successfully loaded icon from: %s\n", icon_path);
            if (g_nid.hIcon && g_nid.hIcon != LoadIconW(NULL, MAKEINTRESOURCEW(32512))) {
                DestroyIcon(g_nid.hIcon);
            }
            g_nid.hIcon = new_icon;
            
            if (g_nid.hWnd) {
                return Shell_NotifyIconW(NIM_MODIFY, &g_nid);
            }
            return TRUE;
        } else {
            DWORD error = GetLastError();
            g_print("Failed to load icon from: %s (error code: %lu)\n", icon_path, error);
        }
    }
    
    return FALSE;
}

void tray_set_left_click_callback(tray_callback_t callback) {
    g_left_click_callback = callback;
}

void tray_set_menu_callback(menu_callback_t callback) {
    g_menu_callback = callback;
}

} // extern "C"
