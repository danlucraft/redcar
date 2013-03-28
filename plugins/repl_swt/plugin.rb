
Plugin.define do
  name    "REPL SWT bindings"
  version "1.0"
  file    "lib", "repl_swt"
  object  "Redcar::REPLSWT"
  dependencies "redcar", ">0"
end