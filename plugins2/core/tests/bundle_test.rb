
module Redcar::Tests
  class BundleTest < Test::Unit::TestCase
    def test_translate_ke
      dict = {
        "@C" => "Ctrl+C",
        "@A" => "Ctrl+A",
        "^@A"=> "Ctrl+Super+A",
        "^A" => "Super+A",
        "~A" => "Alt+A",
        "^~A" => "Super+Alt+A",
        "$^M" => "Super+Shift+M"
      }
      dict.each do |from, to|
        assert_equal to, Redcar::Bundle.translate_key_equivalent(from), from
      end
    end
  end
end
