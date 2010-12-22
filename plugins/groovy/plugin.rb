Plugin.define do
  name    "groovy"
  version "1.0"
  file    "lib", "groovy"
  object  "Redcar::Groovy"
  dependencies "syntax_check", ">0",
               "repl", ">0"
end