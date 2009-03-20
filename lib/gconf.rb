

client = GConf::Client.default
client["/desktop/gnome/url-handlers/redcar/command"] = "/home/dan/projects/redcar/bin/redcar \"%s\""
client["/desktop/gnome/url-handlers/redcar/enabled"] = true
