
module Redcar
  module PluginTests
    class SpeedbarTest < Test::Unit::TestCase
      
      class SpeedbarTestSpeedbar < Speedbar
        label "Line:"
        textbox :line_text
        button "Go", nil, "Return"
      end
  
      def test_show
        sp = SpeedbarTestSpeedbar.instance
        sp.show(win)
        sp.close
      end
    end
  end
end
