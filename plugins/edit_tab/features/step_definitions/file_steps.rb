
# When /^I (?:open|have opened) the file #{FeaturesHelper::STRING_RE}$/ do |filename|
#   When "I press \"Ctrl+O\""
#   When "I set the \"Open\" dialog's filename to \"#{filename}\""
#   When "I click the button \"Open\" in the dialog \"Open\""
# end

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
