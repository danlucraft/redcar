
Plugin.define do
  name    "tree"
  version "1.0"
  file    "lib", "tree"
  object  "Redcar::Tree"
  dependencies "core", ">0",
               "application", ">0"
end