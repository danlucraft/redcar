
Plugin.define do
  name    "Auto Completer"
  version "0.3.2"
  object  "Redcar::AutoCompleter"
  file    "lib", "auto_completer"
  
  dependencies "core",      ">0",
               "edit_view", ">0"
end