
Plugin.define do
  name    "line_tools"
  version "0.1"
  file    "lib", "line_tools"
  object  "Redcar::LineTools"
  dependencies "core", ">0",
               "application", ">0"
end