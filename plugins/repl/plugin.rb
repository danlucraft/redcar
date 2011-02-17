
Plugin.define do
  name    "repl"
  version "1.1"
  file    "lib", "repl"
  object  "Redcar::REPL"
  dependencies "redcar", ">0"
end