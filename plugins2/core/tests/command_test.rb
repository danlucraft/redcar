
module Redcar::Tests
  class CommandTest < Test::Unit::TestCase
    class << self
      attr_accessor :test_var
    end
    
    class TestCommand1 < Redcar::Command
      menu "RedcarTestMenu/TestCommand1"
      key  "Global/Ctrl+Super+Alt+Shift+5"
      
      def initialize(val)
        @val = val
      end
      
      def execute(tab)
        Redcar::Tests::CommandTest.test_var *= @val
      end
    end
    
    def test_execute
      CommandTest.test_var = 2
      TestCommand1.new(10).do(nil)
      assert_equal 20, CommandTest.test_var
    end
    
    def test_added_to_databus
      assert bus("/redcar/commands/").has_child?("Redcar::Tests::CommandTest::TestCommand1")
    end
    
    def test_added_to_menu
      assert bus("/redcar/menus/menubar/RedcarTestMenu/").has_child?("TestCommand1")
    end
    
    def test_added_to_keymap
      assert bus("/redcar/keymaps/Global/").has_child?("Ctrl+Super+Alt+Shift+5")
    end
  end
end
