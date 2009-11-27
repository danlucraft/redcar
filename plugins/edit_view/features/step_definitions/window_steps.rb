Then /^there should be (no|one|\d+) windows?$/ do |num|
  case num
  when "no"
    num = 0
  when "one"
    num = 1
  else
    num = num.to_i
  end
  
  # in the model
  Redcar.app.windows.length.should == num
  
  # in the gui
  display = Swt::Widgets::Display.get_current
  shells  = display.get_shells.to_a
  shells.length.should == num
end

When /I open a new window(?: with title "(.*)")?/ do |title|
  Redcar::Top::NewWindowCommand.new(title).run
end

When /I close the window via command/ do
  Redcar::Top::CloseWindowCommand.new.run
end

When /I close the window via the gui/ do
  win = Redcar.app.focussed_window
  win.controller.swt_event_closed
end

Then /the window "(.*)" should have (\d+) tabs?/ do |win_title, tab_num|
  tab_num = tab_num.to_i

  # in the model
  p Redcar.app.windows
  p win_title
  Redcar.app.windows.detect{|win| win.title == win_title }.notebooks.map{|nb| nb.tabs}.flatten.length.should == tab_num
  
  # in the GUI
  display = Swt::Widgets::Display.get_current
  shells  = display.get_shells.to_a
  shell   = shells.detect {|s| p [s, s.text]; s.text == win_title}
  sash_form = shell.getChildren.to_a.first
  tab_folders = sash_form.children.to_a.select{|c| c.is_a? Swt::Custom::CTabFolder}
  items = tab_folders.map{|f| f.getItems.to_a}.flatten
  items.map {|i| model_tab_for_item(i)}.length.should == tab_num
end