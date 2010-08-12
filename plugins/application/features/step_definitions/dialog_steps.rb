
Given /^I will choose "([^\"]*)" from the "([^\"]*)" dialog$/ do |path, type|
  Redcar.gui.dialog_adapter.should_get_message(:any)
  Redcar.gui.dialog_adapter.set(type.to_sym, path)
end

Then /^I should not see a "([^\"]*)" dialog for the rest of the feature/ do |type|
  Redcar.gui.dialog_adapter.set(type.to_sym, :raise_error)
end

Then /^I should see a message box containing "([^"]*)"$/ do |arg1|
  Redcar.gui.dialog_adapter.should_get_message(arg1)
end
