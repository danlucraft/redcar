
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
    
    def test_should_attach_a_keymap_to_the_global_keymap_point
      @a.push_before(:global)
    end
  
    def test_should_execute_the_command
      @a.push_before(:global)
      @a.add_command(test_command.dup)
      Redcar::Keymap.execute_keystroke("Ctrl+A")
      assert_equal 123, $output
    end
    
    def test_command
      cb = Redcar::CommandBuilder::Builder.new
      cb.name = "Test Command"
      cb.type = :inline
      cb.keybinding = "control a"
      cb.command do 
        $output = 123
      end
      cb
    end
  end
end
