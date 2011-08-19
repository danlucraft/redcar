
Plugin.define do
  name    "application_swt"
  version "1.1"
  file    "lib", "application_swt"
  object  "Redcar::ApplicationSWT"
  dependencies "application", ">0"
end