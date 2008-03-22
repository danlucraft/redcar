module Redcar::Tests
  class CommandHistoryTest < Test::Unit::TestCase
    def test_max
      Redcar::CommandHistory.max = 5
      10.times { win.new_tab(Redcar::Tab, Gtk::Label.new("foo")); tab.close }
      assert_equal 5, Redcar::CommandHistory.history.length
      Redcar::CommandHistory.max = 500
    end
  end
end
