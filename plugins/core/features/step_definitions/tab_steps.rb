
Then /^there should be (\d) tabs? open$/ do |num|
  Redcar.win.tabs.length.should == num.to_i
end
