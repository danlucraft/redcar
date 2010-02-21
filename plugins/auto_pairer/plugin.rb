
Plugin.define do
  name    "auto_pairer"
  version "1.0"
  file    "lib", "auto_pairer"
  object  "Redcar::AutoPairer"
  dependencies "edit_view", ">0"
end