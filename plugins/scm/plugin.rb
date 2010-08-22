Plugin.define do
  name    "scm"
  version "0.1"
  file    "lib", "scm"
  object  "Redcar::Scm::Manager"
  dependencies "project", ">=1.1",
               "application", ">=1.1"
end
