
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestDialog < Test::Unit::TestCase
  def setup
    startup
  end
  
  def teardown
    shutdown
    Redcar::DynamicMacros.clear
  end
  
  def test_find_repeated_sequences
    assert_equal [[1, 2, 3]],
      Redcar::DynamicMacros.find_repeated_sequences([3, 1, 2, 3, 4, 5])
    assert_equal [[1, 2, 3], [3, 1, 2]],
      Redcar::DynamicMacros.find_repeated_sequences([2, 3, 1, 2, 3])
    assert_equal [[1, 2, 3], [3, 1, 2], [2, 3, 1]],
      Redcar::DynamicMacros.find_repeated_sequences([1, 2, 3, 1, 2, 3])
    assert_equal [[2, 1], [1, 2, 1, 2], [2, 1, 2, 1], [1, 2], [1, 2, 1, 2], [1, 2, 1, 2, 1, 2]],
      Redcar::DynamicMacros.find_repeated_sequences([2, 1, 2, 1, 2, 1, 2, 4])
  end
  
  def test_find_repeated_sequence
    assert_equal [[1, 2, 3], 1, 2],
      Redcar::DynamicMacros.find_repeated_sequence([3, 1, 2, 3, 4, 5])
    assert_equal [[1, 2, 3], 2, 1],
      Redcar::DynamicMacros.find_repeated_sequence([2, 3, 1, 2, 3])
    assert_equal [[1, 2, 3], 3, 0],
      Redcar::DynamicMacros.find_repeated_sequence([1, 2, 3, 1, 2, 3])
    assert_equal [[2, 1], 2, 0],
      Redcar::DynamicMacros.find_repeated_sequence([2, 1, 2, 1, 2, 1, 2, 4])
    assert_equal [%w{a b c c}.reverse, 4, 0],
      Redcar::DynamicMacros.find_repeated_sequence("abccabcc".split(//).reverse)
    assert_equal [%w{a b r a c a d}.reverse, 4, 3],
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse)
  end
  
  def test_find_repeated_sequence_repeats
    assert_equal [%w{a b r a c a d}.reverse, 4, 3],
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse)
    assert_equal [%w{b r a c a d a}.reverse, 3, 4],
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 4, 3)
    assert_equal [%w{r a c a d a b}.reverse, 2, 5],
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 3, 4)
    assert_equal [%w{a b r}.reverse, 1, 2],
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 2, 5)
  end
  
  def test_repeat_works_with_complete_trigger
    nt = Redcar.new_tab
    nt.focus
    %w{f o o f o o}.each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foofoo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foofoofoo", nt.contents
  end
  
  def test_works_with_incomplete_trigger
    nt = Redcar.new_tab
    nt.focus
    %w{f o o b a r f o}.each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foobarfo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobar", nt.contents
    %w{1 f o o b a r f o}.each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foobarfoobar1foobarfo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobar1foobarfoobar1", nt.contents
  end
  
  def test_works_multiple
    nt = Redcar.new_tab
    nt.focus
    %w{f o o b a r f o}.each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foobarfo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobar", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobarfoobar", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobarfoobarfoobar", nt.contents
  end
  
  def test_works_predict
    nt = Redcar.new_tab
    nt.focus
    "abracadabra".split(//).each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "abracadabra", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "abracadabracad", nt.contents
    Redcar.keystrokes.issue("ctrl h")
    assert_equal "abracadabracada", nt.contents
    Redcar.keystrokes.issue("ctrl h")
    assert_equal "abracadabracadab", nt.contents
  end
  
  def test_works_predict_and_repeat
    nt = Redcar.new_tab
    nt.focus
    "abracadabra".split(//).each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "abracadabra", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "abracadabracad", nt.contents
    Redcar.keystrokes.issue("ctrl h")
    assert_equal "abracadabracada", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "abracadabracadabracada", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "abracadabracadabracadabracada", nt.contents
  end
  
  def test_predict_does_nothing_after_repeat
    nt = Redcar.new_tab
    nt.focus
    "foobarfo".split(//).each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foobarfo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobar", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foobarfoobarfoobar", nt.contents
        
    Redcar.keystrokes.issue("ctrl h")
    assert_equal "foobarfoobarfoobar", nt.contents
  end
  
  def test_repeat_can_be_undone_as_one_action
    nt = Redcar.new_tab
    nt.focus
    %w{f o o f o o}.each do |l|
      Redcar.keystrokes.issue(l)
    end
    assert_equal "foofoo", nt.contents
    Redcar.keystrokes.issue("ctrl g")
    assert_equal "foofoofoo", nt.contents
    Redcar.keystrokes.issue("ctrl z")
    assert_equal "foofoo", nt.contents
  end
  
  def test_macro_realistic
    @nt = Redcar.new_tab
    @nt.focus
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
    @nt.cursor = :line_start
    2.times { Redcar.keystrokes.issue("Delete") }
    @nt.down
    @nt.cursor = :line_start
    Redcar.keystrokes.issue("Delete")
    7.times { Redcar.keystrokes.issue("control g") }
    resulting_str = test_str.split("\n").map{|line| line[2..-1]}.join("\n")+"\n"
    assert_equal resulting_str, @nt.contents
  end

  def test_works_with_all_commands
    # test this by attempting to re-predict with not just
    # text entry commands
    @nt = Redcar.new_tab
    @nt.focus
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
    2.times { Redcar.keystrokes.issue("Delete") }
    @nt.down
    2.times { Redcar.keystrokes.issue("Delete") }
    Redcar.keystrokes.issue("control g")
    str2=<<END
This is the first line.
his is the second.
# This is the third.
# this is the fourth.
# This is the first line.
# This is the second.
# This is the third.
# this is the fourth.
END
    assert_equal str2, @nt.contents
    Redcar.keystrokes.issue("control h")
    str3=<<END
This is the first line.
This is the second.
# This is the third.
# this is the fourth.
# This is the first line.
# This is the second.
# This is the third.
# this is the fourth.
END
    assert_equal str3, @nt.contents
    Redcar.keystrokes.issue("control g")
    str4=<<END
This is the first line.
This is the second.
This is the third.
# this is the fourth.
# This is the first line.
# This is the second.
# This is the third.
# this is the fourth.
END
    assert_equal str4, @nt.contents
#     resulting_str = test_str.split("\n").map{|line| line[2..-1]}.join("\n")+"\n"
#     assert_equal resulting_str, @nt.contents
  end
  
  def test_fails_gracefully_if_no_repeated_sequence
    nt = Redcar.new_tab
    nt.focus
    nt.clear_command_history
    nt.contents = "foo"
    Redcar.keystrokes.issue("a")
    Redcar.keystrokes.issue("control g")
    assert_equal "fooa", nt.contents
  end
  
  def test_fails_gracefully_if_just_hit_predict
    nt = Redcar.new_tab
    nt.focus
    nt.clear_command_history
    nt.contents = "foo"
    Redcar.keystrokes.issue("control h")
    assert_equal "foo", nt.contents
  end
end
