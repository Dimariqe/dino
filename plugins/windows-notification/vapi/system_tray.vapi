[CCode (cheader_filename = "system_tray_impl.h")]
namespace Dino.Plugins.WindowsNotification.Vapi.SystemTray {
    
    [CCode (cname = "tray_callback_t")]
    public delegate void TrayCallback();
    
    [CCode (cname = "menu_callback_t")]  
    public delegate void MenuCallback(int item_id);
    
    [CCode (cname = "tray_init")]
    public bool init();
    
    [CCode (cname = "tray_add")]
    public bool add();
    
    [CCode (cname = "tray_remove")]
    public bool remove();
    
    [CCode (cname = "tray_hide")]
    public bool hide();
    
    [CCode (cname = "tray_show")]
    public bool show_tray();
    
    [CCode (cname = "tray_set_tooltip")]
    public bool set_tooltip(string tooltip);
    
    [CCode (cname = "tray_set_icon_from_file")]
    public bool set_icon_from_file(string icon_path);
    
    [CCode (cname = "tray_set_left_click_callback")]
    public void set_left_click_callback([CCode (delegate_target = false)] TrayCallback callback);
    
    [CCode (cname = "tray_set_menu_callback")]
    public void set_menu_callback([CCode (delegate_target = false)] MenuCallback callback);
    
    // Menu item IDs
    [CCode (cname = "ID_TRAY_SHOW")]
    public const int MENU_SHOW;
    
    [CCode (cname = "ID_TRAY_EXIT")]
    public const int MENU_EXIT;
}
