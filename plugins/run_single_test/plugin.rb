
Plugin.define do
  name    "run_single_test"
  version "1.0"
  file    "lib", "run_single_test"
  object  "Redcar::RunSingleTest"
  dependencies "redcar", ">0"
end