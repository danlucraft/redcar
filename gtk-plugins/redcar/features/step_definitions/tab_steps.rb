
Then /^there should be #{FeaturesHelper::NUMBER_RE} (?:(\w+?)s?|tabs?) open$/ do |number, tab_type|
  number = parse_number(number)
  if tab_type
    Redcar.win.collect_tabs(Redcar.const_get(tab_type)).length.should == number
  else
    Redcar.win.tabs.length.should == number
  end
end

Then /^the title of the (\w+) should be "([^"]+)"$/ do |tab_type, title| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.title.should == title
end
