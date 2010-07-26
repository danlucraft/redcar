Plugin.define do
  name    "Outline View"
  version "0.1.0"
  file    "lib", "outline_view"
  object  "Redcar::OutlineView"
  dependencies "declarations", ">0",
               "edit_view", ">0",
			         "project", ">0",
			         "document_search", ">0"
end
