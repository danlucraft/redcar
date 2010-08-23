
Plugin.define do
  name    "project"
  version "1.1"
  file    "lib", "project"
  object  "Redcar::Project::Manager"
  dependencies "edit_view", ">0",
               "HTML View", ">0",
               "connection_manager", ">0",
               "application", ">=1.1"
end
