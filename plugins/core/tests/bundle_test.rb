
module Redcar::Tests
  class BundleTest < Test::Unit::TestCase
    def test_translate_ke
      dict = {
        "@c" => "Ctrl+C",
        "@a" => "Ctrl+A",
        "^@a"=> "Ctrl+Super+A",
        "^a" => "Super+A",
        "~a" => "Alt+A",
        "^~a" => "Super+Alt+A",
        "$^m" => "Super+Shift+M",
        "^L" => "Super+Shift+L"
      }
      dict.each do |from, to|
        assert_equal to, Redcar::Bundle.translate_key_equivalent(from), from
      end
    end
  end
end
