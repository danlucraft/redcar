
Plugin.define do
  name "view_shortcuts"
  version "0.1.0"
  
  object "Redcar::ViewShortcuts"
  file "lib", "view_shortcuts"
  
  dependencies "core",      ">0",
               "HTML View", ">=0.3.2"
end