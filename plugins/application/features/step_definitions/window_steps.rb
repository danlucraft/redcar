
Then /^the window should have title "([^\"]*)"$/ do |expected_title|
  first_shell.get_text.should == expected_title
end