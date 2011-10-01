
Plugin.define do
  name    "test_runner"
  version "1.0"
  file    "lib", "test_runner"
  object  "Redcar::TestRunner"
  dependencies "project", ">0",
               "HTML View", ">0",
               "runnables", ">0"
end