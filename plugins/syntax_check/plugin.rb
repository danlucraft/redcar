Plugin.define do
  name    "syntax_check"
  version "0.1"
  file    "lib", "syntax_check"
  object  "Redcar::SyntaxCheck"
  dependencies "edit_view", ">0.9"
end