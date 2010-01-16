
Plugin.define do
  name    "application"
  version "1.0"
  file    "lib", "application"
  object  "Redcar::Application"
  dependencies "core", ">0"
end