
require 'test/unit'

module Redcar::Tests
  class KeymapTests < Test::Unit::TestCase
    include Redcar
    
    def setup
      $output = 0
      @a = Redcar::Keymap.new("Test A")
    end
    
    def test_parse
      assert_equal "Ctrl+N", KeyStroke.parse("control n").to_s
    end
    
    def test_asdf
      assert true
    end
    
  end
end
