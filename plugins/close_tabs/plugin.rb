Plugin.define do
  name "close-tabs"
  version "0.1.0"
  
  object "Redcar::CloseTabs"
  file "lib", "close_tabs"
  
  dependencies  "core", ">0"
end
