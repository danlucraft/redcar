
Given /^there is an edit tab containing "([^\"]*)"$/ do |contents|
  tab = Redcar::Top::NewCommand.new.run
  contents = eval(contents.inspect.gsub("\\\\", "\\"))
  cursor_offset = (contents =~ /<c>/)
  contents = contents.gsub("<c>", "")
  tab.edit_view.document.text = contents
  if cursor_offset
    tab.edit_view.document.cursor_offset = cursor_offset
  end
end

When /^I open a new edit tab$/ do 
  Redcar::Top::NewCommand.new.run
end

When /^I close the focussed tab$/ do
  Redcar::Top::CloseTabCommand.new.run
end

When /I switch (up|down) a tab/ do |type|
  case type
  when "down"
    Redcar::Top::SwitchTabDownCommand.new.run
  when "up"
    Redcar::Top::SwitchTabUpCommand.new.run
  end
end

When /I move (up|down) a tab/ do |type|
  case type
  when "down"
    Redcar::Top::MoveTabDownCommand.new.run
  when "up"
    Redcar::Top::MoveTabUpCommand.new.run
  end
end

Then /^there should be (one|\d+) (.*) tabs?$/ do |num, tab_type|
  if num == "one"
    num = 1
  else
    num = num.to_i
  end
  
  # in the model
  tabs = Redcar.app.focussed_window.notebooks.map {|nb| nb.tabs }.flatten
  tabs.length.should == num
  
  # in the GUI
  case tab_type
  when "edit"
    tab_class = Redcar::EditTab
  end
  
  tabs = get_tabs
  tabs.length.should == num
end

Then /^the edit tab should have the focus$/ do
  tabs = get_tabs
  edit_tabs = tabs.select {|t| t.is_a?(Redcar::EditTab)}
  edit_tabs.length.should == 1
  edit_tabs.first.controller.edit_view.mate_text.get_text_widget.is_focus_control?.should be_true
end

Then /^there should be no open tabs$/ do 
  get_tab_folder.getItems.to_a.length.should == 0
end

Then /^the tab should be focussed within the notebook$/ do
  tab_folder = get_tab_folder
  tab_folder.get_selection.should == tab_folder.getItems.to_a.first
end

Then /^the tab should have the keyboard focus$/ do
  tab = get_tab(get_tab_folder)
  tab.controller.edit_view.is_current?.should be_true
end

Then /^I should (not )?see "(.*)" in the edit tab$/ do |bool, content|
  content = content.gsub("\\n", "\n")
  bool = !bool
  matcher = bool ? be_true : be_false
  focussed_tab.edit_view.document.to_s.include?(content).should matcher
end


