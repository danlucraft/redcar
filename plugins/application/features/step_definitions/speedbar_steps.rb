
Then /^the (.*) speedbar should be open$/ do |class_name|
  Redcar.app.focussed_window.speedbar.class.to_s.should == class_name
end

def get_speedbar_text_field(field_name, speedbar=nil)
  speedbar ||= Redcar.app.focussed_window.speedbar
  item = speedbar.__get_item_by_label(field_name) ||
          speedbar.__get_item_by_label(field_name + ":") ||
          speedbar.__get_item(field_name)
  expected_klass = Redcar::Speedbar::TextBoxItem
  unless item.is_a?(expected_klass)
    raise "expected #{item} to be a #{expected_klass}"
  end
  item
end

def get_speedbar_field(field_name, expected_klass, speedbar=nil)
  speedbar ||= Redcar.app.focussed_window.speedbar
  item = speedbar.__get_item_by_text_or_name(field_name)
  unless item.is_a?(expected_klass)
    raise "expected #{item} to be a #{expected_klass}"
  end
  item
end

When /^I type "([^"]*)" into the "([^"]*)" field in the speedbar$/ do |text, field_name|
  get_speedbar_text_field(field_name).edit_view.document.text = text
end

When /^I press "([^"]*)" in the speedbar$/ do |button_name|
  speedbar = Redcar.app.focussed_window.speedbar
  speedbar.controller.execute_listener_in_model(speedbar.__get_item_by_text_or_name(button_name))
end

When /^I check "([^"]*)" in the speedbar$/ do |checkbox_name|
  speedbar = Redcar.app.focussed_window.speedbar
  item = speedbar.__get_item_by_text_or_name(checkbox_name)
  item.set_value(true)
  speedbar.controller.execute_listener_in_model(item, true)
end

When /^I uncheck "([^"]*)" in the speedbar$/ do |checkbox_name|
  speedbar = Redcar.app.focussed_window.speedbar
  item = speedbar.__get_item_by_text_or_name(checkbox_name)
  item.set_value(false)
  speedbar.controller.execute_listener_in_model(item, false)
end

When /^I choose "([^"]*)" in the "([^"]*)" field in the speedbar$/ do |value, combo_name|
  speedbar = Redcar.app.focussed_window.speedbar
  item = get_speedbar_field(combo_name, Redcar::Speedbar::ComboItem)
  item.set_value(value)
  speedbar.controller.execute_listener_in_model(item, value)
end

When /^I close the speedbar$/ do
  Redcar.app.focussed_window.close_speedbar
end

Then /^the "([^"]*)" field in the speedbar should have text "([^"]*)"$/ do |field_name, text|
  get_speedbar_text_field(field_name).edit_view.document.to_s.should == text
end

Then /^"([^"]*)" should( not)? be checked in the speedbar$/ do |checkbox_name, negate|
  speedbar = Redcar.app.focussed_window.speedbar
  item = speedbar.__get_item_by_text_or_name(checkbox_name)
  if negate
    item.value.should be_false
  else
    item.value.should be_true
  end
end

Then /^"([^"]*)" should be chosen in the "([^"]*)" field in the speedbar$/ do |value, combo_name|
  speedbar = Redcar.app.focussed_window.speedbar
  item = get_speedbar_field(combo_name, Redcar::Speedbar::ComboItem, speedbar)
  item.value.should == value
end

Then /^there should( not)? be an open speedbar$/ do |negate|
  speedbar = Redcar.app.focussed_window.speedbar
  if negate
    speedbar.should == nil
  else
    speedbar.should_not == nil
  end
end