Plugin.define do
  name    "scm_hg"
  version "0.1"
  file    "lib", "scm_hg"
  object  "Redcar::Scm::Mercurial::Manager"
  dependencies "scm", ">0"
end
