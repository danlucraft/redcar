When /I open the runnables tree/ do
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

Then /^I should see (\d+) windows?$/ do |window_count|
  Redcar.app.windows.size.should == window_count.to_i
end