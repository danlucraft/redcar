

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestMacros < Test::Unit::TestCase
  def setup
    startup
    @nt = Redcar.new_tab
    @nt.focus
  end

  def teardown
    shutdown
  end
  
  def test_macro
    Redcar.keystrokes.issue("ctrl-shift (")
    Redcar.keystrokes.issue("a")
    Redcar.keystrokes.issue("ctrl-shift )")
    assert_equal "a", @nt.contents
    Redcar.keystrokes.issue("ctrl-shift E")
    assert_equal "aa", @nt.contents
  end
  
  def test_macro_works_with_commands
    @nt.contents = ""
    Redcar.keystrokes.issue("ctrl-shift (")
    Redcar.keystrokes.issue("a")
    @nt.insert_at_cursor(" ")
    Redcar.keystrokes.issue("ctrl-shift )")
    assert_equal "a ", @nt.contents
    Redcar.keystrokes.issue("ctrl-shift E")
    assert_equal "a a ", @nt.contents
  end
  
  def test_macro_realistic
    test_str=<<END
# This is the first line.
# This is the second.
# This is the third.
# this is the fourth.
# This is the first line.
# This is the second.
# This is the third.
# this is the fourth.
END
    @nt.contents = test_str
    @nt.cursor = 0
    3.times {@nt.right}
    Redcar.keystrokes.issue("ctrl-shift (")
    @nt.cursor = :line_start
    2.times { Redcar.keystrokes.issue("Delete") }
    @nt.down
    Redcar.keystrokes.issue("ctrl-shift )")
    7.times { Redcar.keystrokes.issue("ctrl-shift E") }
    resulting_str = test_str.split("\n").map{|line| line[2..-1]}.join("\n")+"\n"
    assert_equal resulting_str, @nt.contents
  end
end
