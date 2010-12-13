Plugin.define do
  name    "java"
  version "0.1"
  file    "lib", "syntax_check", "java"
  object  "Redcar::SyntaxCheck::Java"
  dependencies "syntax_check", ">0"
end