
module FeaturesHelper
  STRING_RE = /"((?:[^"]|\\")+)"/
  NUMBER_RE = /(\d+|one|two|three|four|five|six|seven|eight|nine|ten)/
  ORDINALS = {
    "first" => 1,
    "second" => 2,
    "third" => 3,
    "fourth" => 4,
    "fifth" => 5,
    "sixth" => 6,
    "seventh" => 7,
    "eighth" => 8,
    "ninth" => 9,
    "tenth" => 10
  }
  ORDINAL_RE = /(#{ORDINALS.keys.join("|")})/
  
  def parse_number(number)
    numbers = %w(one two three four five six seven eight nine ten)
    result = numbers.index(number) || (number.to_i - 1)
    result + 1
  end
  
  def parse_ordinal(ordinal)
    ORDINALS[ordinal]
  end
  
  def only(array)
    array.length.should == 1
    array.first
  end
end
