
client = GConf::Client.default
bin_path = File.expand_path(File.dirname(__FILE__) + "/../bin/redcar")
# Add redcar:// handlers 
client["/desktop/gnome/url-handlers/redcar/command"] = "#{bin_path} \"%s\""
client["/desktop/gnome/url-handlers/redcar/enabled"] = true
# Add txmt:// handlers to make some Bundles that use this work
client["/desktop/gnome/url-handlers/txmt/command"] = "#{bin_path} \"%s\""
client["/desktop/gnome/url-handlers/txmt/enabled"] = true
if in_features_process?
  client["/desktop/gnome/url-handlers/redcar-features/command"] = "#{bin_path} --dbus-features \"%s\""
  client["/desktop/gnome/url-handlers/redcar-features/enabled"] = true
end
