
Then /I should see "(.*)" in the web view/ do |expected|
  p body
  body.include?(expected)
end