
Then /I should see "(.*)" in the web view/ do |expected|
  body.include?(expected)
end

Given /^I fill in "(.*)" with "(.*)" in the web view$/ do |field, value|
  fill_in(field, :with => value)
end

When /I press "(.*)" in the web view/ do |button_name|
  click_button(button_name)
end
