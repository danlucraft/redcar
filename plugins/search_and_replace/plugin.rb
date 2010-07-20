Plugin.define do
  name    "search_and_replace"
  version "0.1"
  file    "lib", "search_and_replace"
  object  "Redcar::SearchAndReplace"
  dependencies "redcar", ">0"
end