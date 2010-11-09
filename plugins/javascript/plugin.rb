Plugin.define do
  name    "javascript"
  version "0.1"
  file    "lib", "syntax_check", "javascript"
  object  "Redcar::SyntaxCheck::JavaScript"
  dependencies "syntax_check", ">0"
end