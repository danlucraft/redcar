
Then /^the window should have title "([^\"]*)"$/ do |expected_title|
  active_shell.get_text.should == expected_title
end