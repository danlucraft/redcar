module Redcar::Tests
  class CommandHistoryTest < Test::Unit::TestCase
    class HistoryTestCommand < Redcar::Command
      def execute
      end
    end
    
    class HistoryTestCommand2 < Redcar::Command
      norecord
      def execute
      end
    end
    
    def setup
      Redcar::CommandHistory.clear
    end
    
    def test_records_execution
      HistoryTestCommand.new.do
      assert_equal 1, Redcar::CommandHistory.history.length
      assert_equal HistoryTestCommand, Redcar::CommandHistory.history.first.class
    end
    
    def test_does_not_record_norecord
      HistoryTestCommand2.new.do
      assert_equal 0, Redcar::CommandHistory.history.length
    end
    
    def test_max
      Redcar::CommandHistory.max = 5
      10.times { HistoryTestCommand.new.do }
      assert_equal 5, Redcar::CommandHistory.history.length
      Redcar::CommandHistory.max = 500
    end
  end
end
