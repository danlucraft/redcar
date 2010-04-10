
Given /^I will choose "([^\"]*)" from the "([^\"]*)" dialog$/ do |path, type|
  Redcar.gui.register_dialog_adapter(FakeDialogAdapter.new)
  Redcar.gui.dialog_adapter.set(type.to_sym, path)
end

Then /^I should not see a "([^\"]*)" dialog for the rest of the feature/ do |type|
  Redcar.gui.register_dialog_adapter(FakeDialogAdapter.new)
  Redcar.gui.dialog_adapter.set(type.to_sym, :raise_error)
end