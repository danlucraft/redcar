
Given /^I have opened the ProjectTab$/ do
  Redcar::OpenProject.new.do
end

When /^I add the directory "([^"]+)" to the ProjectTab$/ do |dir| # "
  Redcar::AddDirectoryToProjectCommand.new(dir).do
end
