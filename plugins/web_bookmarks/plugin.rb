
Plugin.define do
  name    "web_bookmarks"
  version "1.0"
  file    "lib", "web_bookmarks"
  object  "Redcar::WebBookmarks"
  dependencies "tree",        ">0",
               "application", ">=1.1",
               "project"    , ">=1.1",
               "HTML View"  , ">0"
end