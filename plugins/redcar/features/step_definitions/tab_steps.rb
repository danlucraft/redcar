
NUMBER_RE = /(\d+|one|two|three|four|five|six|seven|eight|nine|ten)/
def parse_number(number)
  numbers = %w(one two three four five six seven eight nine ten)
  result = numbers.index(number) || (number.to_i - 1)
  result + 1
end

Then /^there should be #{NUMBER_RE} (?:(\w+)s?|tabs?) open$/ do |number, tab_type|
  number = parse_number(number)
  if tab_type
    Redcar.win.collect_tabs(Redcar.const_get(tab_type)).length.should == number
  else
    Redcar.win.tabs.length.should == number
  end
end

Then /^the title of the (\w+) should be "([^"]+)"$/ do |tab_type, title| # "
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  tab.title.should == title
end
