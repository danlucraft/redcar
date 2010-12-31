Plugin.define do
  name    "mirah"
  version "1.0"
  file    "lib", "mirah"
  object  "Redcar::Mirah"
  dependencies "syntax_check", ">0",
               "repl", ">0"
end