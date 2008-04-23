
module Redcar::Tests
  class CommandRangeTest < Test::Unit::TestCase

    class SpeedbarTestSpeedbar < Redcar::Speedbar
      label "Line:"
      textbox :line_text
      button "Go", nil, "Return"
    end

    def test_validate
      assert !Redcar::Range.valid?(1)
      assert Redcar::Range.valid?(Redcar::EditTab)
      assert Redcar::Range.valid?(SpeedbarTestSpeedbar)
      assert Redcar::Range.valid?(Redcar::Window)
    end

  end
end
