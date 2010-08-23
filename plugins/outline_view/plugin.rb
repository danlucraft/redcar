Plugin.define do
  name    "outline_view"
  version "0.1.0"
  file    "lib", "outline_view"
  object  "Redcar::OutlineView"
  dependencies  "declarations", ">0",
                "edit_view", ">0",
                "document_search", ">0", 
                "outline_view_swt", ">0"
end
