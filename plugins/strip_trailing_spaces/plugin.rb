Plugin.define do
  name    "Strip Trailing Spaces"
  version "0.3"
  file     "lib", "strip_trailing_spaces"
  object  "Redcar::StripTrailingSpaces"
  dependencies "redcar", ">0",
               "edit_view", ">0"
end
