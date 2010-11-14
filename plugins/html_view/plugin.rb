
Plugin.define do
  name "HTML View"
  version "0.3.2"
  
  object "Redcar::HtmlView"
  file "lib", "html_view"
  
  dependencies "core", ">0",
               "application", ">0",
               "application_swt", ">0",
               "edit_view", ">0"
end
