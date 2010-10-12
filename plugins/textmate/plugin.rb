
Plugin.define do
  name    "textmate"
  version "1.0"
  file    "lib", "textmate"
  object  "Redcar::Textmate"
  dependencies "core", ">0", "application", ">0", "HTML View", ">=0.3.2", "tree", ">0",
      "runnables", ">=1.1", "edit_view", ">0"
end
