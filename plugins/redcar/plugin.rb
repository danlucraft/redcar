
Plugin.define do
  name    "redcar"
  version "1.0"
  file    "redcar"
  object  "Redcar::Top"
  dependencies "core",              ">0", # includes Storage
               "application",       ">=1.1",
               "project",           ">0",
               "Auto Completer",    ">0",
               "auto_indenter",     ">0",
               "document_search",   ">0",
               "runnables",         ">0",
               "HTML View",         ">=0.3.2",
               "Plugin Manager UI", ">=0.3.2",
               "Outline View",      ">0"
end