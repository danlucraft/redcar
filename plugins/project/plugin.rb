
Plugin.define do
  name    "project"
  version "1.0"
  file    "lib", "project"
  object  "Redcar::Project"
  dependencies "edit_view", ">0"
end