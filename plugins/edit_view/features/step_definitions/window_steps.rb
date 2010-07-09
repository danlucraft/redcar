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
  
  # on OSX there is always an invisible window
  diff = Redcar.platform == :osx ? 1 : 0
  
  shells.length.should == num + diff
end

When /I open a new window(?: with title "(.*)")?/ do |title|
  Redcar::Top::NewWindowCommand.new(title).run
end

class FakeEvent
  def initialize(event_type, widget)
    untyped_event = Swt::Widgets::Event.new.tap do |e|
      e.display = Swt.display
      e.widget = widget
      e.x = 0
      e.y = 0
    end
    widget.notify_listeners(event_type, untyped_event)
  end
end
                                                                                                                                             
When /^I maximize the window size$/ do
  Redcar.app.focussed_window.controller.shell.maximized = true
end

When /^I restore the window size$/ do
  Redcar.app.focussed_window.controller.shell.maximized = false
end

When /I close the window(?: "(.*)")?( with a command| through the gui)?/ do |title, how|
  if title
    win = Redcar.app.windows.detect{|win| win.title == title }
  else
    win = nil
  end
  if how =~ /command/
    Redcar::Top::CloseWindowCommand.new.run(win)
  else
    unless win
      display = Swt::Widgets::Display.get_current
      shell = display.get_active_shell
      win = Redcar.app.windows.detect {|w| w.controller.shell == shell }
    end
    FakeEvent.new(Swt::SWT::Close, win.controller.shell)
  end
end

When /^I focus the window "([^\"]*)" with a command$/ do |title|
  win = Redcar.app.windows.detect{|win| win.title == title }
  win.focus
end

When /^I focus the window "([^\"]*)" through the gui$/ do |title|
  win = Redcar.app.windows.detect{|win| win.title == title }
  FakeEvent.new(Swt::SWT::Activate, win.controller.shell)
end

When /^I focus the working directory window through the gui$/ do
  When "I focus the window \"#{File.basename Dir.pwd}\" through the gui"
end

Then /^the window should be titled "([^\"]*)"$/ do |title|
  windows = Redcar.app.windows
  windows.length.should == 1
  
  # in the model
  windows.first.title.should == title
  # in the gui
  windows.first.controller.shell.text.should == title
end

Then /the window "(.*)" should have (\d+) tabs?/ do |win_title, tab_num|
  tab_num = tab_num.to_i

  # in the model
  Redcar.app.windows.detect{|win| win.title == win_title }.notebooks.map{|nb| nb.tabs}.flatten.length.should == tab_num
  
  # in the GUI
  display = Swt::Widgets::Display.get_current
  shells = display.get_shells.to_a
  shell = shells.detect {|s| s.text == win_title }
  items = get_tab_folders(shell).map{|f| f.getItems.to_a}.flatten
  
  items.map {|i| model_tab_for_item(i)}.length.should == tab_num
end