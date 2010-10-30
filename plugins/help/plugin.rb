
Plugin.define do
  name    "help"
  version "1.0"
  file    "lib", "help"
  object  "Redcar::Help"
  dependencies "web_bookmarks", ">0"
end