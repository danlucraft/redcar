
When /^I do nothing$/ do
end

Given /^there is an edit tab containing "([^\"]*)"$/ do |contents|
  Swt.sync_exec do
    tab = Redcar::Top::OpenNewEditTabCommand.new.run
    contents = eval(contents.inspect.gsub("\\\\", "\\"))
    cursor_offset = (contents =~ /<c>/)
    contents = contents.gsub("<c>", "")
    tab.edit_view.document.text = contents
    if cursor_offset
      tab.edit_view.document.cursor_offset = cursor_offset
    end
  end
end

When /^I open a new edit tab$/ do
  Swt.bot.menu("File").menu("New").click
end

When /^I open a new edit tab titled "(.*)"$/ do |title|
  Swt.sync_exec do
    tab = Redcar::Top::OpenNewEditTabCommand.new.run
    tab.title = title
  end
end

When /^I close the focussed tab$/ do
  Swt.bot.menu("File").menu("Close Tab").click
end

When /^the edit tab updates its contents$/ do
  Swt.sync_exec do
    implicit_edit_view.check_for_updated_document
  end
end

When /I switch (up|down) a tab/ do |type|
  Swt.sync_exec do
    case type
    when "down"
      Redcar::Application::SwitchTabDownCommand.new.run
    when "up"
      Redcar::Application::SwitchTabUpCommand.new.run
    end
  end
end

When /I move (up|down) a tab/ do |type|
  Swt.sync_exec do
    case type
    when "down"
      Redcar::Application::MoveTabDownCommand.new.run
    when "up"
      Redcar::Application::MoveTabUpCommand.new.run
    end
  end
end

module SwtbotHelpers

  def get_tab_folders(shell=active_shell)
    tab_folders = notebook_sash(shell).children.to_a.select do |c|
      c.class == Java::OrgEclipseSwtCustom::CTabFolder
    end
  end
  
  def get_tab_folder
    get_tab_folders.length.should == 1
    get_tab_folders.first
  end
end

World(SwtbotHelpers)

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
  Swt.sync_exec do
    get_tab_folder.children.to_a.length.should == num
  end
end

Then /^the edit tab should have the focus$/ do
  Swt.sync_exec do
    implicit_edit_view.controller.mate_text.get_text_widget.is_focus_control?.should be_true
  end
end

Then /^there should be no open tabs$/ do
  Swt.sync_exec { get_tab_folder.getItems.to_a.length.should == 0 }
end

Then /^the tab should be focussed within the notebook$/ do
  Swt.sync_exec do
    tab_folder = get_tab_folder
    tab_folder.get_selection.should == tab_folder.getItems.to_a.first
  end
end

Then /^the tab should have the keyboard focus$/ do
  Swt.sync_exec do
    tab = get_tab(get_tab_folder)
    implicit_edit_view.controller.is_current?.should be_true
  end
end

Then /^I should (not )?see "(.*)" in the edit tab$/ do |bool, content|
  Swt.sync_exec do
    content = content.gsub("\\n", "\n")
    bool = !bool
    matcher = bool ? be_true : be_false
    implicit_edit_view.document.to_s.include?(content).should matcher
  end
end

Then /^my active tab should be "([^"]*)"$/ do |name|
  Swt.sync_exec do
    focussed_tab.title.should == name
  end
end

Then /^my active tab should have an "([^"]*)" icon$/ do |arg1|
  Swt.sync_exec do
    focussed_tab.icon.should == :"#{arg1}"
  end
end

Then /^the tab should (not )?have annotations$/ do |negated|
  Swt.sync_exec do
    annotations = implicit_edit_view.annotations
    negated ? (annotations.should be_empty) : (annotations.should_not be_empty)
  end
end

Then /^the tab should (not )?have an annotation on line (\d+)$/ do |negated, num|
  Swt.sync_exec do
    annotations = implicit_edit_view.annotations(:line => num.to_i)
    negated ? (annotations.should be_empty) : (annotations.should_not be_empty)
  end
end
