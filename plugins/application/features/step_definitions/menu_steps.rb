
Then /^there should be a main menu$/ do
  main_menu.should_not be_nil
end

Then /^the main menu should contain "([^\"]*)" entries$/ do |entries|
  entries = entries.split(",").map {|e| e.strip }
  items = main_menu.get_items.to_a
  items.should_not be_empty
  texts = items.map {|item| item.get_text }
  entries.all? {|e| texts.include?(e)   }
end
