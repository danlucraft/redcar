
module Redcar
  module PluginTests
    class TabTest < Test::Unit::TestCase
      def setup
        Redcar::App.close_window(Redcar.win, false)
        Redcar::App.new_window
      end

      def test_true
      end
    end
  end
end
