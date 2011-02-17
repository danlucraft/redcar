
Given /^I will choose "([^\"]*)" from the "([^\"]*)" dialog$/ do |path, type|
  Redcar.gui.dialog_adapter.should_get_message(:any)
  Redcar.gui.dialog_adapter.set(type.to_sym, path)
end

Given /^I would type "([^"]*)" in an input box$/ do |params|
  Redcar.gui.dialog_adapter.add_input(params)
end

Then /^I should not see a "([^\"]*)" dialog for the rest of the feature/ do |type|
  Redcar.gui.dialog_adapter.set(type.to_sym, :raise_error)
end

Then /^I should see a message box containing "([^"]*)"$/ do |arg1|
  Redcar.gui.dialog_adapter.should_get_message(arg1)
end

Then /^I should see a popup text box with title "([^"]*)" and containing "([^"]*)"$/ do |title,text|
  Redcar.gui.dialog_adapter.should_get_popup_message(title,text)
end

Then /^I should see a popup html box containing "([^"]*)"$/ do |text|
  Redcar.gui.dialog_adapter.should_get_popup_html(text)
end