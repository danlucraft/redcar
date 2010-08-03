Plugin.define do
  name    "scm-svn"
  version "0.1"
  file    "lib", "scm-svn"
  object  "Redcar::SCM::Subversion::Manager"
  dependencies "scm", ">0"
end
