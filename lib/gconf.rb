

client = GConf::Client.default
bin_path = File.expand_path(File.dirname(__FILE__) + "/../bin/redcar")
client["/desktop/gnome/url-handlers/redcar/command"] = "#{bin_path} \"%s\""
client["/desktop/gnome/url-handlers/redcar/enabled"] = true
