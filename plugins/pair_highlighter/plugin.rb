
Plugin.define do
  name    "pair_highlighter"
  version "1.0"
  file    "lib", "pair_highlighter"
  object  "Redcar::PairHighlighter"
  dependencies "edit_view", ">0",
               "textmate",  ">0"
end
