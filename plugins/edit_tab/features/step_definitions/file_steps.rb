
When /^I (?:open|have opened) the file #{FeaturesHelper::STRING_RE}$/ do |filename|
  When "I press \"Ctrl+O\""
  Gutkumber.tick
  When "I set the \"Open\" dialog's filename to \"#{filename}\""
  Gutkumber.tick
  When "I click the button \"Open\" in the dialog \"Open\""
end

When /^I save the EditTab$/ do
  When "I press \"Ctrl+S\""
end

When /^I save the EditTab as #{FeaturesHelper::STRING_RE}$/ do |filename|
  Redcar::SaveTabAs.new(filename).do
end
