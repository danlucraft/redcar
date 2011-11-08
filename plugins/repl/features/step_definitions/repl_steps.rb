When /^I open a "([^"]*)" repl$/ do |repl|
  Swt.sync_exec do
    Redcar.const_get(repl.camelize).const_get("Open" + repl.camelize + "REPL").new.run
  end
end

When /^I open a new repl$/ do
  Swt.sync_exec do
    Redcar::REPL::OpenFakeREPL.new.run
  end
end

Then /^the REPL output should be "([^"]*)"$/ do |output|
  Swt.sync_exec do
    current_tab.edit_view.document.mirror.last_output.should == output
  end
end

Then /^the current command should be "([^"]*)"$/ do |cmd|
  Swt.sync_exec do
    current_tab.current_command.should == cmd
  end
end

Then /^the current command should be blank$/ do
  Swt.sync_exec do
    current_tab.current_command.should == nil
  end
end
