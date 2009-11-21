
Given /^I will choose "([^\"]*)" from the "([^\"]*)" dialog$/ do |path, type|
  Redcar.gui.register_dialog_adapter(FakeDialogAdapter.new)
  Redcar.gui.dialog_adapter.set(type.to_sym, path)
end
