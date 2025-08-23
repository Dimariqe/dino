using Dino.Entities;
using Qlite;

namespace Dino {

public class Util {
    public static Message.Type get_message_type_for_conversation(Conversation conversation) {
        switch (conversation.type_) {
            case Conversation.Type.CHAT:
                return Entities.Message.Type.CHAT;
            case Conversation.Type.GROUPCHAT:
                return Entities.Message.Type.GROUPCHAT;
            case Conversation.Type.GROUPCHAT_PM:
                return Entities.Message.Type.GROUPCHAT_PM;
            default:
                assert_not_reached();
        }
    }

    public static Conversation.Type get_conversation_type_for_message(Message message) {
        switch (message.type_) {
            case Entities.Message.Type.CHAT:
                return Conversation.Type.CHAT;
            case Entities.Message.Type.GROUPCHAT:
                return Conversation.Type.GROUPCHAT;
            case Entities.Message.Type.GROUPCHAT_PM:
                return Conversation.Type.GROUPCHAT_PM;
            default:
                assert_not_reached();
        }
    }

    public static bool is_pixbuf_supported_mime_type(string mime_type) {
        if (mime_type == null) return false;

        foreach (Gdk.PixbufFormat pixbuf_format in Gdk.Pixbuf.get_formats()) {
            foreach (string pixbuf_mime in pixbuf_format.get_mime_types()) {
                if (pixbuf_mime == mime_type) return true;
            }
        }
        return false;
    }
    
    public static void launch_default_for_uri(string file_uri)
    {
#if _WIN32
        try {
            // Convert URI to local path if it's a file:// URI
            string path_to_open = file_uri;
            if (file_uri.has_prefix("file://")) {
                var file = File.new_for_uri(file_uri);
                path_to_open = file.get_path();
                if (path_to_open == null) {
                    // Fallback: manually decode the URI
                    path_to_open = file_uri.substring(8); // Remove "file:///"
                    path_to_open = Uri.unescape_string(path_to_open);
                }
            }
            
            debug("Trying to open file: %s", path_to_open);
            
            // Use cmd /c start which is the most reliable way on Windows
            string[] argv = { 
                "cmd.exe", 
                "/c", 
                "start", 
                "", // Empty title to avoid issues with paths that contain spaces
                path_to_open 
            };
            
            var process = new Subprocess.newv(argv, SubprocessFlags.NONE);
            debug("Successfully launched file with cmd /c start");
            
        } catch(Error e) {
            warning("Failed to open file with default application: %s", e.message);
            // Fallback to GTK's default method
            try {
                AppInfo.launch_default_for_uri(file_uri, null);
            } catch(Error e2) {
                warning("GTK fallback also failed: %s", e2.message);
            }
        }
#else
        AppInfo.launch_default_for_uri(file_uri, null);
#endif
    }
    
    public static string get_content_type(FileInfo fileInfo)
    {
#if _WIN32
        string fileName = fileInfo.get_name();
        int fileNameLength = fileName.length;
        int extIndex = fileName.last_index_of(".");
        if (extIndex < fileNameLength)
        {
            string extension = fileName.substring(extIndex, fileNameLength - extIndex);
            string mime_type = ContentType.get_mime_type(extension);
            if (mime_type != null && mime_type.length != 0)
            {
                return mime_type;
            }
        }
#endif
        return fileInfo.get_content_type();
    }
}

}
