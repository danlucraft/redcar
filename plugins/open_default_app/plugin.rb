
Plugin.define do
  name    "open_default_app"
  version "0.2"
  file    "lib", "open_default_app.rb"
  object  "Redcar::OpenDefaultApp"
  dependencies "redcar", ">0"
end