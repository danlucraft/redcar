
module NotebookSwtHelper
  def sash
    sash = first_shell.children.to_a.first
  end
  
  def ctab_folders
    sash.children.to_a.select do |c| 
      c.class == Java::OrgEclipseSwtCustom::CTabFolder
    end
  end
end

World(NotebookSwtHelper)

When /^I make a new notebook$/ do
  Redcar::Top::NewNotebookCommand.new.run
end

When /^I move the tab to the other notebook$/ do
  Redcar::Top::MoveTabToOtherNotebookCommand.new.run
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
