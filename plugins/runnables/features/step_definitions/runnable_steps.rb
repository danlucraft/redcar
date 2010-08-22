When /^I open the runnables tree$/ do
  Redcar::Runnables::ShowRunnables.new.run
end

When /^I change the command to "([^"]*)"$/ do |name|
  current = File.read(runnable_config)
  File.open(runnable_config, 'w') do |f|
    f.print current.gsub("An app", name)
  end
end

When /^I go back to the first window$/ do
  Redcar.app.windows.first.focus
end

When /^I note the number of windows$/ do
  @windows = Redcar.app.windows.size
end

Then /^I should see (\d+) more windows?$/ do |window_count|
  Redcar.app.windows.size.should == (@windows + window_count.to_i)
end