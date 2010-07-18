Plugin.define do
  name    "find-in-project"
  version "0.1.0"

  object  "Redcar::FindInProject"
  file    "lib", "find_in_project"

  dependencies "core",      ">0",
               "HTML View", ">=0.3.2"
end
