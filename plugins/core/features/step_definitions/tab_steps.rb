
def escape_text(text)
  text.gsub("\\n", "\n").gsub("\\t", "\t")
end

Then /^I should see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.visible_contents_as_string.should include(escape_text(text))
end

Then /^I should not see "([^"]+)" in the (\w+)$/ do |text, tab_type| # "
  text = eval(text.inspect)
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.visible_contents_as_string.should_not include(escape_text(text))
end
