
Then /^there should be one (.*) tab$/ do |tab_type|
  case tab_type
  when "edit"
    tab_class = Redcar::EditTab
  end
  
  display = Redcar::ApplicationSWT.display
  shell   = display.get_shells.to_a.first
  tab_folder = shell.getChildren.to_a.first
  item1 = tab_folder.getItems.to_a.first
  tab = Redcar.app.windows.first.notebook.tabs.detect{|t| t.controller.item == item1}
  tab_folder.getItems.to_a.length.should == 1
  tab.should be_an_instance_of tab_class
end
