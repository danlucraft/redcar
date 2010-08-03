Plugin.define do
  name    "scm"
  version "0.1"
  file    "lib", "scm"
  object  "Redcar::SCM::Manager"
  dependencies "project", ">=1.1",
               "application", ">=1.1"
end
