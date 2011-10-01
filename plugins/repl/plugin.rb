
Plugin.define do
  name    "repl"
  version "1.1"
  file    "lib", "repl"
  object  "Redcar::REPL"
  dependencies "edit_view", ">0"
end