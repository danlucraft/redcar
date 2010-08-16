Plugin.define do
  name    "scm-hg"
  version "0.1"
  file    "lib", "scm-hg"
  object  "Redcar::Scm::Mercurial::Manager"
  dependencies "scm", ">0"
end
