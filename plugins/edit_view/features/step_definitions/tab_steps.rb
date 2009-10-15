
Then /^there should be one (.*) tab$/ do |tab_type|
  case tab_type
  when "edit"
    tab_class = Redcar::EditTab
  end
  
  display = Redcar::ApplicationSWT.display
  shell   = display.get_shells.to_a.first
  tab_folder = shell.getChildren.to_a.first
  p tab_folder.getItems.to_a
  p Redcar.app.windows.first.notebook.tabs
  tab_folder.getItems.to_a.length.should == 1
end
