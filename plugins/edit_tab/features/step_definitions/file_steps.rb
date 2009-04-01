
When /^I (?:open|have opened) the file "([^"]+)"$/ do |filename|
  Redcar::OpenTab.new(filename).do
end

When /^I save the EditTab$/ do
  Redcar::SaveTab.new.do
end

When /^I save the EditTab as #{FeaturesHelper::STRING_RE}$/ do |filename|
  Redcar::SaveTabAs.new(filename).do
end
