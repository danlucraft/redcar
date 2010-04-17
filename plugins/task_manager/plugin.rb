
Plugin.define do
  name "task_manager"
  version "0.3.5"
  
  object "Redcar::TaskManager"
  file "lib", "task_manager"
  
  dependencies "core",      ">0",
               "HTML View", ">=0.3.2"
end