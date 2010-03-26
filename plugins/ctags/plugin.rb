Plugin.define do
  name    "CTags"
  version "0.0.2"
  file    "lib", "ctags"
  object  "Redcar::CTags"
  dependencies "project", ">0"
end