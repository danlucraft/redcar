
Plugin.define do
  name    "paren_highlighter"
  version "1.0"
  file    "lib", "paren_highlighter"
  object  "Redcar::ParenHighlighter"
  dependencies "edit_view", ">0",
               "textmate",  ">0"
end
