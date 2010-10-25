
Plugin.define do
  name    "clipboard_viewer"
  version "1.0"
  file    "lib", "clipboard_viewer"
  object  "Redcar::ClipboardViewer"
  dependencies "application",">0",
               "redcar"     ,">0"
end