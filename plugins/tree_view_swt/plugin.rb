
Plugin.define do
  name    "tree_view_swt"
  version "1.0"
  file    "lib", "tree_view_swt"
  object  "Redcar::TreeViewSWT"
  dependencies "core", ">0",
               "application_swt", ">0"
end