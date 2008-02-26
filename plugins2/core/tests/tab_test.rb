
module Redcar
  module PluginTests
    class TabTest < Test::Unit::TestCase
      def setup
        Redcar::App.close_window(win, false)
        Redcar::App.new_window
      end
      
      def test_true
        p :no_tests
      end
    end
  end
end
