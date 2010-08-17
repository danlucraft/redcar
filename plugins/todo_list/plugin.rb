
Plugin.define do
  name "todo_list"
  version "1.0.0"
  
  object "Redcar::TodoList"
  file "lib", "todo_list"
  
  dependencies "core",      ">0",
               "HTML View", ">=0.3.2"
end
