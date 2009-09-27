
Given /^I (?:open|have opened) the file #{FeaturesHelper::STRING_RE}$/ do |filename|
  Redcar::OpenTabCommand.new(filename).do
end

Given /^I do not have permission to write to #{FeaturesHelper::STRING_RE}$/ do |filename|
  File.writable?(filename).should be_false
end

When /^I save the EditTab$/ do
  When "I press \"Ctrl+S\""
end

When /^I save the EditTab as #{FeaturesHelper::STRING_RE}$/ do |filename|
  Redcar::SaveTabAs.new(filename).do
end

Then /^the "([^\"]*)" dialog's current directory should be "([^\"]*)"$/ do |title, directory|
  dialog = Gutkumber.find_gtk_window(title)
  regex_dir = Regexp.new(directory)
  regex_dir.match(dialog.current_folder).should be_true
end
