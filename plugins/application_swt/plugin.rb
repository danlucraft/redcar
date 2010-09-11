
Plugin.define do
  name    "application_swt"
  version "1.0"
  file    "lib", "application_swt"
  object  "Redcar::ApplicationSWT"
  dependencies "application", ">0",
               "swt",         ">0"
end