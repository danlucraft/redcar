
Plugin.define do
  name "macros"
  version "1.0"
  file "lib", "macros"
  object "Redcar::Macros"
  dependencies "application", ">0",
              "edit_view",   ">0",
              "HTML View",   ">0"
end