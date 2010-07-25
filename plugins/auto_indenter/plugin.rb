
Plugin.define do
  name    "auto_indenter"
  version "1.0"
  file    "lib", "auto_indenter"
  object  "Redcar::AutoIndenter"
  dependencies "edit_view", ">0",
               "auto_pairer", ">0"
end