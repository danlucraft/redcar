Plugin.define do
  name    "markdown"
  version "0.1"
  file    "lib", "markdown"
  object  "Redcar::Markdown"
  dependencies "application", ">0", 
               "HTML View", ">=0.3.2"
end