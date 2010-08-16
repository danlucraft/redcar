Plugin.define do
  name    "scm_git"
  version "0.1"
  file    "lib", "scm_git"
  object  "Redcar::Scm::Git::Manager"
  dependencies "scm", ">0"
end
