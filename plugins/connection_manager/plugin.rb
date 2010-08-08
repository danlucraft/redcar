
Plugin.define do
  name "connection_manager"
  version "0.0.1"
  
  object "Redcar::ConnectionManager"
  file "lib", "connection_manager"
  
  dependencies "core", ">0",
               "HTML View", ">=0.3.2"  
  
end