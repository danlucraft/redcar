
Plugin.define do
  name    "REPL SWT bindings"
  version "1.0"
  file    "lib", "repl_swt"
  object  "Redcar::ReplSWT"
  dependencies "redcar", ">0",
               "edit_view", ">0",
               "repl", ">1.0"
end