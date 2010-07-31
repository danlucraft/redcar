
Plugin.define do
  name    "scm-hg"
  version "0.1"
  file    "lib", "manager"
  object  "Redcar::SCM::Mercurial::Manager"
  dependencies "scm", ">0"
end
