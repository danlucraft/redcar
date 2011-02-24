
Plugin.define do
  name    "runnables"
  version "1.0"
  file    "lib", "runnables"
  object  "Redcar::Runnables"
  dependencies "application", ">=1.1",
               "HTML View",   ">0"
end