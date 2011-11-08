
def filter_dialog
  dialog(Redcar::ApplicationSWT::FilterListDialogController::FilterListDialog)
end

def filter_dialog_items
  filter_dialog.list.get_items.to_a
end

Then /^there should be a filter dialog open$/ do
  Swt.sync_exec do
    filter_dialog.should_not be_nil
  end
end

Then /^there should be no filter dialog open$/ do
  Swt.sync_exec do
    filter_dialog.should be_nil
  end
end

When /^I set the filter to "(.*)"$/ do |text|
  Swt.sync_exec do
    filter_dialog.text.set_text(text)
  end
end

When /^I select in the filter dialog$/ do
  Swt.sync_exec do
    filter_dialog.controller.selected
  end
end

When /^I wait "(.*)" seconds?$/ do |time|
  s = Time.now + time.to_f
  sleep 0.1 until Time.now > s
end

Then /^the filter dialog should have (no|\d+) entr(?:y|ies)$/ do |num|
  Swt.sync_exec do
    num = (num == "no" ? 0 : num.to_i)
    filter_dialog_items.length.should == num
  end
end

Then /^I should see "(.*)" at (\d+) the filter dialog$/ do |text, pos|
  Swt.sync_exec do
    pos = pos.to_i
    filter_dialog_items[pos].should == text
  end
end

Then /^I should not see "(.*)" in the filter dialog$/ do |text|
  Swt.sync_exec do
    filter_dialog_items.include?(text).should be_false
end
end
