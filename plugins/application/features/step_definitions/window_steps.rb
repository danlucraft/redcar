
Then /^the window should have title "([^\"]*)"$/ do |expected_title|
  actual_title = Redcar::ApplicationSWT.display.get_active_shell.get_text
  actual_title.should == expected_title
end