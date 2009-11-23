
Given /^I have open a file$/ do
  Redcar::Project::FileOpenCommand.new.run
end

When /^I open a file$/ do
  Redcar::Project::FileOpenCommand.new.run
end

Given /^I have opened "([^\"]*)"$/ do |arg1|
  Redcar::Project::FileOpenCommand.new(arg1).run
end

When /^I save the tab$/ do
  Redcar::Project::FileSaveCommand.new.run
end

When /^I save the tab as$/ do
  Redcar::Project::FileSaveAsCommand.new.run
end

Then /^the file "([^\"]*)" should contain "([^\"]*)"$/ do |arg1, arg2|
  File.read(arg1).should == arg2
end
