Plugin.define do
  name    "groovy"
  version "0.1"
  file    "lib", "syntax_check", "groovy"
  object  "Redcar::SyntaxCheck::Groovy"
  dependencies "syntax_check", ">0"
end