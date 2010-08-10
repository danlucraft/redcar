
Plugin.define do
  name    "auto_highlighter"
  version "1.0"
  file    "lib", "auto_highlighter"
  object  "Redcar::AutoHighlighter"
  dependencies "edit_view", ">0",
               "textmate",  ">0"
end
