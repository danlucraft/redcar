
Then /^there should be a main menu$/ do
  Swt.bot.menu("File").should_not be_nil
end

Then /^the main menu should contain "([^\"]*)" entries$/ do |entries|
  entry_names = entries.split(",").map {|e| e.strip }
  entry_names.each {|name| Swt.bot.menu(name).should_not be_nil }
end

Then /^the "([^\"]*)" menu should contain a "([^\"]*)" entry$/ do |menu_text, entry_text|
  Swt.bot.menu(menu_text).menu(entry_text).should_not be_nil
end

Then /^the menu item "([^\"]*)\|([^\"]*)" should be (active|inactive)$/ do |menu_name, menu_item, active|
  items = main_menu.get_items.to_a
  menu = items.detect {|i| i.text == get_menu_name(menu_name)}
  items = menu.get_menu.get_items.to_a
  item = items.detect {|i| i.text.split("\t").first == menu_item }
  case active
  when "active"
    item.enabled.should be_true
  when "inactive"
    item.enabled.should be_false
  end
end

When /^I (?:open the|click) "([^"]*)" from the "([^"]*)" menu$/ do |menu_item, menu_name|
  menu_items = menu_name.split("/").inject(main_menu.get_items.to_a.dup) do |items, item_name|
    m = items.detect {|i| i.text == get_menu_name(item_name)}
    items = m.get_menu.get_items.to_a
  end
  item = menu_items.detect {|i| i.text.split("\t").first == menu_item }
  FakeEvent.new(Swt::SWT::Selection, item)
end

When /I select menu item "(.*)"/ do |menu_path|
  bits = menu_path.split("|")
  curr = Swt.bot
  bits.each { |bit| curr = curr.menu(bit) }
  curr.click
end



