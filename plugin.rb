
Plugin.define do
  name    "go-to-github"
  version "0.1b"
  file    "lib", "go_to_github"
  object  "Redcar::GoToGithub"
  dependencies "redcar", ">0"
end
