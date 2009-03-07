
Then /^I should see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.contents_as_text.include?(text).should be_true
end
