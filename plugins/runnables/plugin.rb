
Plugin.define do
  name    "runnables"
  version "1.0"
  file    "lib", "runnables"
  object  "Redcar::Runnables"
  dependencies "HTML View",   ">0",
               "project", ">0"
end