
Then /^there should be #{FeaturesHelper::NUMBER_RE} panes?$/ do |num|
  Redcar.win.panes.length.should == parse_number(num)
end

Then /^there should be panes like$/ do |tree|
  bus["/gtk/window/panes_container"].data.debug_widget_tree.chomp.should == tree
end
