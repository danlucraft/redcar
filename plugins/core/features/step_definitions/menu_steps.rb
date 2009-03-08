
def open_menus
  menus = []
  ObjectSpace.each_object(Gtk::Menu) { |m| menus << m if m.visible? }
  menus
end

When /^I choose "([^"]+)" from the menu$/ do |option| # "
  only(open_menus).children.each do |child|
    child.activate if child.child.text == option
  end
end

Then /^I should see a menu with "([^"]+)"$/ do |option| # "
  options = []
  only(open_menus).children.each do |child|
    if child.child.respond_to?(:text)
      options << child.child.text
    else
      child.child.children.each do |child2|
        if child2.respond_to?(:text)
          options << child2.text
        end
      end
    end
  end
  options.include?(option).should be_true
end
