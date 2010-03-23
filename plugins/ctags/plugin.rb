Plugin.define do
  name    "CTags"
  version "0.1"
  file    "lib", "ctags"
  object  "Redcar::CTags"
  dependencies "project", ">0"
end