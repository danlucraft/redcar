
def filter_dialog
  dialog(Redcar::ApplicationSWT::FilterListDialogController::FilterListDialog)
end

def filter_dialog_items
  filter_dialog.list.get_items.to_a
end

Then /^there should be a filter dialog open$/ do
  filter_dialog.should_not be_nil
end

Then /^there should be no filter dialog open$/ do
  filter_dialog.should be_nil
end

When /^I set the filter to "(.*)"$/ do |text|
  filter_dialog.text.set_text(text)
end

When /^I select in the filter dialog$/ do
  filter_dialog.controller.selected
end

When /^I wait "(.*)" seconds?$/ do |time|
  Cucumber::Ast::StepInvocation.wait_time = time.to_f
end

Then /^the filter dialog should have (no|\d+) entr(?:y|ies)$/ do |num|
  num = (num == "no" ? 0 : num.to_i)
  filter_dialog_items.length.should == num
end

Then /^I should see "(.*)" at (\d+) the filter dialog$/ do |text, pos|
  pos = pos.to_i
  filter_dialog_items[pos].should == text
end

Then /^I should not see "(.*)" in the filter dialog$/ do |text|
  filter_dialog_items.include?(text).should be_false
end
