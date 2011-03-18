
Plugin.define do
  name    "key_bindings"
  version "1.0"
  file    "lib", "key_bindings"
  object  "Redcar::KeyBindings"
  dependencies "redcar", ">0"
end