
Plugin.define do
  name    "test_runner"
  version "1.0"
  file    "lib", "test_runner"
  object  "Redcar::TestRunner"
  dependencies "redcar", ">0"
end