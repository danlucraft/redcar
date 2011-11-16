
Then /^there should be a main menu$/ do
  Swt.bot.menu("File").should_not be_nil
end

Then /^the main menu should contain "([^\"]*)" entries$/ do |entries|
  Swt.sync_exec do
    entry_names = entries.split(",").map {|e| e.strip }
    entry_names.each {|name| Swt.bot.menu(name).should_not be_nil }
  end
end

Then /^the "([^\"]*)" menu should contain a "([^\"]*)" entry$/ do |menu_text, entry_text|
  Swt.bot.menu(menu_text).menu(entry_text).should_not be_nil
end

Then /^the menu item "([^\"]*)\|([^\"]*)" should be (active|inactive)$/ do |menu_name, menu_item, active|
  Swt.sync_exec do
    item = Swt.bot.menu(menu_name).menu(menu_item)
    case active
    when "active"
      item.should be_enabled
    when "inactive"
      item.should_not be_enabled
    end
  end
end

When /^I (?:open the|click) "([^"]*)" from the "([^"]*)" menu$/ do |menu_item, menu_name|
  raise "use 'I select menu item ()' instead"
end

When /I select menu item "(.*)"/ do |menu_path|
  Swt.sync_exec do
    bits = menu_path.split(/\||\//)
    curr = Swt.bot
    bits.each { |bit| curr = curr.menu(bit) }
    curr.click
  end
end



