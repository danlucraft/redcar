
Plugin.define do
  name    "execute_current_tab"
  version "0.0"
  file    "lib", "execute_current_tab.rb"
  object  "Redcar::ExecuteCurrentTab"
  dependencies "redcar",              ">0" # I assume it does transitive?
end