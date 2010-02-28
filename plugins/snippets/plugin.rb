
Plugin.define do
  name    "snippets"
  version "1.0"
  file    "lib", "snippets"
  object  "Redcar::Snippets"
  dependencies "edit_view", ">0",
               "textmate",  ">0"
end