Given /^I will set "([^"]*)" as a parameter$/ do |arg1|
  Redcar.gui.dialog_adapter.add_input(arg1)
end

When /^I open the runnables tree$/ do
  Redcar::Runnables::ShowRunnables.new.run
end

When /^I change the command to "([^"]*)"$/ do |name|
  current = File.read(runnable_config)
  File.open(runnable_config, 'w') do |f|
    f.print current.gsub("An app", name)
  end
end

When /^I go back to the "([^"]*)" window$/ do |title|
  Redcar.app.windows.detect { |w| w.title == title }.focus
end

When /^I note the number of windows$/ do
  @windows = Redcar.app.windows.size
end

Then /^I should see (\d+) more windows?$/ do |window_count|
  Redcar.app.windows.size.should == (@windows + window_count.to_i)
end