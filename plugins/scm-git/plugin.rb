
Plugin.define do
  name    "scm-git"
  version "0.1"
  file    "lib", "manager"
  object  "Redcar::SCM::Git::Manager"
  dependencies "scm", ">0"
end
