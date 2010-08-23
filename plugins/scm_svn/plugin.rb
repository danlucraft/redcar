Plugin.define do
  name    "scm_svn"
  version "0.1"
  file    "lib", "scm_svn"
  object  "Redcar::Scm::Subversion::Manager"
  dependencies "scm", ">0"
end
