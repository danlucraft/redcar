
Then /^there should be one tab$/ do
  display = Redcar::ApplicationSWT.display
  shell   = display.get_shells.first
  tab_folder = shell.getChildren.to_a.first
  tab_folder.getItems.to_a.length.should == 1
end
