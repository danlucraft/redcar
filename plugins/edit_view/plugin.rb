
Plugin.define do
  name    "edit_view"
  version "1.0"
  file    "lib", "edit_view"
  object  "Redcar::EditView"
  dependencies "core", ">0",
               "application", ">0"
end