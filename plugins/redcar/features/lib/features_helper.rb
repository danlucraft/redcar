
module FeaturesHelper
  STRING_RE = /"((?:[^"]|\\")+)"/
  NUMBER_RE = /(\d+|one|two|three|four|five|six|seven|eight|nine|ten)/
  
  def parse_number(number)
    numbers = %w(one two three four five six seven eight nine ten)
    result = numbers.index(number) || (number.to_i - 1)
    result + 1
  end
  
  def only(array)
    array.length.should == 1
    array.first
  end
end
