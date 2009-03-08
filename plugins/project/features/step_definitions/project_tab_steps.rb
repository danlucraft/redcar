
Given /^the ProjectTab is open$/ do
  When 'I press "Ctrl+Shift+P"'
end

When /^I (?:add|have added) the directory "([^"]+)" to the ProjectTab$/ do |dir| # "
  Redcar::AddDirectoryToProjectCommand.new(dir).do
end

When /^I (?:remove|have removed) the directory "([^"]+)" from the ProjectTab$/ do |dir| # "
  Redcar::RemoveDirectoryFromProjectCommand.new(dir).do
end

When /^I open "([^"]+)" in the ProjectTab$/ do |name| # "
  tab = only(Redcar.win.collect_tabs(Redcar::ProjectTab))
  i = tab.store.find_iter(1, name)
  tab.view.expand_row(i.path, false)
end

When /^I close "([^"]+)" in the ProjectTab$/ do |name| # "
  tab = only(Redcar.win.collect_tabs(Redcar::ProjectTab))
  i = tab.store.find_iter(1, name)
  tab.view.collapse_row(i.path)
end

When /^I create a file "([^"]+)" in the project plugin's features directory$/ do |fn|
  File.open("plugins/project/features/" + fn, "w") do |f|
    f.puts "foo"
  end
end

When /^I cleanup the file "([^"]+)" in the project plugin's features directory$/ do |fn|
  FileUtils.rm_f("plugins/project/features/" + fn)

end
