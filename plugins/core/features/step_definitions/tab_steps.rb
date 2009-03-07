
Then /^there should be (\d) (?:(\w+)s?|tabs?) open$/ do |num, type|
  if type
    Redcar.win.collect_tabs(Redcar.const_get(type)).length.should == num.to_i
  else
    Redcar.win.tabs.length.should == num.to_i
  end
end
