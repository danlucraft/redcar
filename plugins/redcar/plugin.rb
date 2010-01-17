
Plugin.define do
  name    "redcar"
  version "1.0"
  file    "redcar"
  object  "Redcar::Top"
  dependencies "core",           ">0",
               "application",    ">0",
               "project",        ">0",
               "Auto Completer", ">0"
end