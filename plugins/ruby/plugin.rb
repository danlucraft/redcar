Plugin.define do
  name    "ruby"
  version "0.2"
  file    "lib", "ruby"
  object  "Redcar::Ruby"
  dependencies "syntax_check", ">0",
               "repl", ">0"
end
