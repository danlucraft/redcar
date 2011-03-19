When /^I open a "([^"]*)" repl$/ do |repl|
  Redcar.const_get(repl.camelize).const_get("Open" + repl.camelize + "REPL").new.run
end

When /^I open a new repl$/ do
  Redcar::REPL::OpenFakeREPL.new.run
end

Then /^the REPL output should be "([^"]*)"$/ do |output|
  current_tab.edit_view.document.mirror.last_output.should == output
end

Then /^the current command should be "([^"]*)"$/ do |cmd|
  current_tab.current_command.should == cmd
end

Then /^the current command should be blank$/ do
  current_tab.current_command.should == nil
end
