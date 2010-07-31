
Then /^the main menu should contain "([^\"]*)" entries$/ do |entries|
  entries = entries.split(",").map {|e| e.strip }
  entries.all? {|e| bot.menu(e) rescue nil }.should be_true
end

Then /^the "([^\"]*)" menu should contain a "([^\"]*)" entry$/ do |menu_text, entry_text|
  (bot.menu(menu_text).menu(entry_text) rescue nil).should_not be_nil
end

Then /^the menu item "([^\"]*)\|([^\"]*)" should be (active|inactive)$/ do |menu_name, menu_item, active|
  item = bot.menu(menu_name).menu(menu_item)
  case active
  when "active"
    item.is_enabled.should be_true
  when "inactive"
    item.is_enabled.should be_false
  end
end
