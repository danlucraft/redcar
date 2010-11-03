When /^I type the fixture path of "([^"]*)" in the "([^"]*)" field in the speedbar$/ do |filename,field|
  path = File.join(web_fixtures_path,filename)
  When "I type \"" + path + "\" into the \"" + field + "\" field in the speedbar"
end

When /^I open the web bookmarks tree$/ do
  Redcar::WebBookmarks::ShowTree.new.run
end

When /^I open a web preview$/ do
  Redcar::WebBookmarks::FileWebPreview.new.run
end
