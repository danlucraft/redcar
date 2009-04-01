
def escape_text(text)
  text.gsub("\\n", "\n").gsub("\\t", "\t")
end

def only_tab(tab_type)
  only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
end

Then /^I should see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  tab = only_tab(tab_type)
  tab.visible_contents_as_string.should include(escape_text(text))
end

Then /^I should not see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  text = eval(text.inspect)
  tab = only_tab(tab_type)
  tab.visible_contents_as_string.should_not include(escape_text(text))
end

When /^I close the tab$/ do
  Redcar::CloseTab.new.do
end

When /^I save all the open tabs$/ do
  Redcar::SaveAllTabsCommand.new.do
end

Then /^the label of the (\w+) should say "([^"]+)"$/ do |tab_type, label|
  tab = only_tab(tab_type)
  tab.title.should == label
end

Then /^there should be #{FeaturesHelper::NUMBER_RE} ([A-Z]\w+)$/ do |num, tab_type|
  Redcar.win.collect_tabs(Redcar.const_get(tab_type)).length.should == parse_number(num)
end
