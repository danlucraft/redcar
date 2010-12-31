
Plugin.define do
  name    "Terminal"
  version "0.1"
  file    "lib", "terminal"
  object  "Redcar::Terminal"
  dependencies "redcar", ">0",
               "repl",">0"
end