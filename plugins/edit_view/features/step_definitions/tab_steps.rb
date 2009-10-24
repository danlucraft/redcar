
Then /^there should be one (.*) tab$/ do |tab_type|
  case tab_type
  when "edit"
    tab_class = Redcar::EditTab
  end
  
  tab_folder = get_tab_folder
  tab = get_tab(tab_folder)
  tab_folder.getItems.to_a.length.should == 1
  tab.should be_an_instance_of tab_class
end

def get_tab_folder
  display = Redcar::ApplicationSWT.display
  shell   = display.get_shells.to_a.first
  tab_folder = shell.getChildren.to_a.first
end

def get_tab(tab_folder)
  item1 = tab_folder.getItems.to_a.first
  tab = Redcar.app.windows.first.notebook.tabs.detect{|t| t.controller.item == item1}
end

Then /^the tab should be focussed within the notebook$/ do
  tab_folder = get_tab_folder
  tab_folder.get_selection.should == tab_folder.getItems.to_a.first
end

Then /^the tab should have the keyboard focus$/ do
  tab_folder = get_tab_folder
  tab = get_tab(tab_folder)
  tab.controller.edit_view.has_focus?.should be_true
end

Then /^I should see "(.*)" in the edit tab$/ do |content|
  tab_folder = get_tab_folder
  tab = get_tab(tab_folder)
  tab.edit_view.document.to_s.include?(content).should be_true
end
