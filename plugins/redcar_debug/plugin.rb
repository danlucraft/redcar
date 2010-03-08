
Plugin.define do
  name    "redcar_debug"
  version "1.0"
  file    "lib", "redcar_debug"
  object  "Redcar::Debug"
  dependencies "redcar", ">0"
end