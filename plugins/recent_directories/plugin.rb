Plugin.define do
  name "recent_directories"
  version "1.0"
  file "lib", "recent_directories"
  object  "Redcar::RecentDirectories"
  dependencies "redcar", ">0"
end