
Plugin.define do
  name "Connections Manager"
  version "0.0.1"
  
  object "Redcar::ConnectionsManager"
  file "lib", "connection_manager"
  
  dependencies "core", ">0",
               "HTML View", ">=0.3.2"  
  
end