
Given /^there is an? EditTab open with syntax "([^"]+)"$/ do |syntax|
  When 'I press "Super+N"'
  When 'I press "Ctrl+Alt+Shift+R"'
  When 'I press "1"'
end

When /^I type "([^"]+)"$/ do |text|
  text.split(//).each do |letter|
    case letter
    when " "
      press_key("Space")
    when "\n"
      press_key("Return")
    else
      press_key(letter)
    end
  end
end

Then /^the current syntax should be "([^"]+)"$/ do |syntax|
  Redcar.win.focussed_tab.document.parser.grammar.name.should == syntax
end
