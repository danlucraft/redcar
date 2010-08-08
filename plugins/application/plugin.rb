
Plugin.define do
  name    "application"
  version "1.1"
  file    "lib", "application"
  object  "Redcar::Application"
  dependencies "core", ">0"
end