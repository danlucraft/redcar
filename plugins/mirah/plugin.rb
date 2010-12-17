Plugin.define do
  name    "mirah"
  version "0.1"
  file    "lib", "mirah"
  object  "Redcar::SyntaxCheck::Mirah"
  dependencies "syntax_check", ">0"
end