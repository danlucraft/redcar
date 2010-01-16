
Plugin.define do
  name    "my_plugin"
  version "1.0"
  file    "lib", "my_plugin"
  object  "Redcar::MyPlugin"
  dependencies "redcar", ">0"
end