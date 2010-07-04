
Plugin.define do
  name    "project"
  version "1.0"
  file    "lib", "project"
  object  "Redcar::Project::Manager"
  dependencies "edit_view", ">0",
               "HTML View", ">0"
end