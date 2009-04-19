
Given /^there is an? EditTab open(?: with syntax #{FeaturesHelper::STRING_RE})?$/ do |syntax|
  When 'I press "Ctrl+T"'
  if syntax
    case syntax
    when "Ruby"
      When 'I press "Ctrl+Alt+Shift+R" then "5"'
    when "Ruby on Rails"
      When 'I press "Ctrl+Alt+Shift+R" then "6"'
    else
      raise "features don't know how to activate #{syntax} syntax"
    end
  end
end

Given /^the EditTab contains #{FeaturesHelper::STRING_RE}$/ do |text|
  text = parse_string(text)
  tab = only(Redcar.win.collect_tabs(Redcar::EditTab))
  tab.document.text = text
end

When /^I (?:type|have typed) "([^"]+)"$/ do |text|
  bits = text.split(//).reverse
  while letter = bits.pop
    case letter
    when "\\"
      case bits.pop
      when "n"
        press_key("Return")
      end
    else
      press_key(letter)
    end
  end
end

Then /^the current syntax should be "([^"]+)"$/ do |syntax|
  Redcar.win.focussed_tab.document.parser.grammar.name.should == syntax
end
