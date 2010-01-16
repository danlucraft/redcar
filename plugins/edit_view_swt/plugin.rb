
Plugin.define do
  name    "edit_view_swt"
  version "1.0"
  file    "lib", "edit_view_swt"
  object  "Redcar::EditViewSWT"
  dependencies "core", ">0",
               "application_swt", ">0"
end