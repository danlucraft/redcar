
Then /^the (.*) speedbar should be open$/ do |class_name|
  Redcar.app.focussed_window.speedbar.class.to_s.should == class_name
end

When /^I type "([^"]*)" into the "([^"]*)" field in the speedbar$/ do |text, field_name|
  speedbar = Redcar.app.focussed_window.speedbar
  speedbar.send(field_name).edit_view.document.text = text
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