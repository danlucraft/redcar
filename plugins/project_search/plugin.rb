
Plugin.define do
  name    "project_search"
  version "1.0"
  file    "lib", "project_search"
  object  "ProjectSearch"
  dependencies "project", ">0"
end