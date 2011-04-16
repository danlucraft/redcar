
module NotebookSwtHelper
  def notebook_sash
    Redcar.app.show_toolbar = false
    Redcar.app.refresh_toolbar!
    active_shell.children.to_a.last.children.to_a[0]
  end
  
  def ctab_folders
    notebook_sash.children.to_a.select do |c| 
      c.class == Java::OrgEclipseSwtCustom::CTabFolder
    end
  end
end

World(NotebookSwtHelper)

When /^I make a new notebook$/ do
  Redcar::Application::OpenNewNotebookCommand.new.run
end

When /^I move the tab to the other notebook$/ do
  Redcar::Application::MoveTabToOtherNotebookCommand.new.run
end

When /^I close the current notebook$/ do
  Redcar::Application::CloseNotebookCommand.new.run
end

When /^I switch notebooks$/ do
  Redcar::Application::SwitchNotebookCommand.new.run
end

Then /^there should be (one|two) notebooks?$/ do |count_str|
  count = count_str == "one" ? 1 : 2
  # in the model
  Redcar.app.windows.first.notebooks.length.should == count
  
  # in the GUI
  ctab_folders.length.should == count
end


Then /^notebook (\d) should have (\d) tabs?$/ do |index, tab_count|
  index = index.to_i - 1
  # in the model
  Redcar.app.windows.first.notebooks[index].tabs.length.should == tab_count.to_i
  
  # in the GUI
  ctab_folders[index].children.to_a.length.should == tab_count.to_i
end

Then /^the tab in notebook (\d) should contain "([^\"]*)"$/ do |index, str|
  index = index.to_i - 1
  # in the model
  tab = Redcar.app.windows.first.notebooks[index].focussed_tab
  tab.edit_view.document.to_s.include?(str).should be_true
end

