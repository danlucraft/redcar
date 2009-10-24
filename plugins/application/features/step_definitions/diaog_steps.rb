
Given /^I will choose "([^\"]*)" from the open_file dialog$/ do |path|
  Redcar.gui.register_dialog_adapter(Redcar::ApplicationSWT::FakeDialogAdapter.new)
  Redcar.gui.dialog_adapter.set(:open_file, path)
end
