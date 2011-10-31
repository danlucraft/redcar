
When /^I open the web bookmarks tree$/ do
  Swt.sync_exec { Redcar::WebBookmarks::ShowWebBookmarksCommand.new.run }
end
