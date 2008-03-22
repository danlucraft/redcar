
module Redcar::Tests
  class CommandTest < Test::Unit::TestCase
    class << self
      attr_accessor :test_var
    end
    
    class TestCommand1 < Redcar::Command
      def initialize(val)
        @val = val
      end
      
      def execute(tab)
        Redcar::Tests::CommandTest.test_var *= @val
      end
    end
    
    def test_execute
      CommandTest.test_var = 2
      TestCommand1.new(10).execute(nil)
      assert_equal 20, CommandTest.test_var
    end
    
    def test_added_to_databus
      assert bus("/redcar/commands/").has_child?("Redcar::Tests::CommandTest::TestCommand1")
    end
  end
end
