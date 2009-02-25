

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestTextTab < Test::Unit::TestCase
  def setup
    startup
    @nt = Redcar.new_tab
    @nt.focus
  end

  def teardown
    shutdown
  end
  
  def assert_contents(str)
    assert_equal str, @nt.contents
  end
 
  def test_contents
    @nt.contents = "foobarbaz"
    assert_contents "foobarbaz"
  end
  
  def test_undo_replace
    @nt.replace("foobarbaz")
    assert_contents "foobarbaz"
    @nt.undo
    assert_contents ""
  end
  
  def test_insert
    @nt.contents = "foobaz"
    @nt.insert(3, "bar")
    assert_contents "foobarbaz"
  end
  
  def test_delete
    @nt.contents = "foobarbaz"
    @nt.delete(3, 6)
    assert_contents "foobaz"
  end
  
  def test_get_brackets
    @nt.contents = "foobarbaz"
    assert_equal "b", @nt[3]
    assert_equal "bar", @nt[3..5]
    
    assert_equal "z", @nt[-1]
    assert_equal "bar", @nt[3...6]
    assert_equal "oobarbaz", @nt[1..-1]
  end
  
  def test_set_brackets
    @nt.contents = "goobaz"
    @nt[0] = "f"
    assert_contents "foobaz"
    @nt[3] = "barb"
    assert_contents "foobarbaz"
    @nt[6..8] = "qux"
    assert_contents "foobarqux"
    @nt[0..5] = "pre"
    assert_contents "prequx"   
  end
  
  def test_length_and_to_s
    @nt.contents = "foobarbaz"
    assert_equal 9, @nt.length
    assert_equal "foobarbaz", @nt.to_s
  end
  
  def test_modified
    assert_equal false, @nt.modified?
    @nt.contents = "foobar"
    assert_equal true, @nt.modified?
    @nt.modified = false
    assert_equal false, @nt.modified?
    @nt[2] = "w"
    assert_equal true, @nt.modified?
  end
  
  def test_cursor
    @nt.contents = "foofoo\nbarbar\nbazbaz"
    @nt.cursor = 0
    @nt.left
    assert_equal 0, @nt.cursor_offset
    @nt.right
    assert_equal 1, @nt.cursor_offset
    @nt.down
    assert_equal 8, @nt.cursor_offset
    3.times { @nt.right } 
    @nt.up
    assert_equal 0, @nt.cursor_offset
    @nt.cursor = :tab_start
    assert_equal 0, @nt.cursor_offset
    @nt.cursor = :line_end
    assert_equal 6, @nt.cursor_offset
    @nt.cursor = :tab_end
    assert_equal 20, @nt.cursor_offset
    @nt.cursor = :line_start
    assert_equal 14, @nt.cursor_offset
  end
  
  def test_up_and_down_go_to_start_of_line_if_line_is_short
    @nt.contents = "foobar\n\nbazbar"
    @nt.cursor = 10
    @nt.up
    assert_equal 7, @nt.cursor_offset
    
    @nt.contents = "foobar\n\nbazbar"
    @nt.cursor = 3
    @nt.down
    assert_equal 7, @nt.cursor_offset
  end
  
  def test_up_and_down_do_not_cycle
    @nt.contents = "foo\nbar\nbaz"
    @nt.cursor = 2
    @nt.up
    assert_equal 0, @nt.cursor_offset
    
    @nt.cursor = 9
    @nt.down
    assert_equal 10, @nt.cursor_offset
  end
  
#   def test_composable_words
#     @nt.contents = ""
#     (%w{a b c}+[" "]+%w{1 2 3}+[" "]+%w{a b c d} + [" "]).each do |l|
#       @nt.insert_at_cursor l
#     end
#     assert_contents "abc 123 abcd "
#     @nt.undo
#     assert_contents "abc 123 abcd"
#     @nt.undo
#     assert_contents "abc 123"
#   end
  
#   def test_composable_spaces
#     @nt.contents = ""
#     10.times { @nt.insert_at_cursor " " }
#     @nt.undo
#     assert_contents ""
#   end
  
#   def test_composable_words_delete
#     @nt.contents = "abc 123 abcd "
#     @nt.cursor = 0
#     7.times { @nt.delete(0, 1) }
#     assert_contents " abcd "
#     @nt.undo
#     assert_contents "123 abcd "
#     @nt.undo
#     assert_contents "abc 123 abcd "
#   end
  
#   def test_composable_spaces_delete
#     @nt.contents = " "*10
#     @nt.cursor = 0
#     7.times { @nt.delete(0, 1) }
#     assert_contents " "*3
#     @nt.undo
#     assert_contents " "*10
#   end
  
  def test_selected?
    @nt.contents = "foobarbaz"
    assert_equal false, @nt.selected?
  end
  
  def test_set_and_get_selection
    @nt.contents = "foobarbaz"
    @nt.select(3, 5)
    assert_equal [3, 5], @nt.selection_bounds
  end
  
  def test_shift_right_selects
    @nt.contents = "foo"*5+"\n"+"bar"*5+"\n"+"baz"*5
    @nt.cursor = 0
    assert_equal "", @nt.selection
    5.times { @nt.shift_right }
    assert_equal [0, 5], @nt.selection_bounds
    @nt.down
    assert_equal "", @nt.selection
  end
  
  def test_shift_down_selects
    @nt.contents = "foo"*5+"\n"+"bar"*5+"\n"+"baz"*5
    @nt.cursor = 0
    assert_equal "", @nt.selection
    @nt.shift_down
    assert_equal [0, 16], @nt.selection_bounds
  end  
  def test_cut
    @nt.contents = "foobarbaz"
    @nt.select(3, 6)
    @nt.cut
    assert_equal "foobaz", @nt.contents
    assert_equal "bar", Clipboard.top
  end
  
  def test_copy
    @nt.contents = "foobarbaz"
    @nt.select(3, 6)
    @nt.copy
    assert_equal "foobarbaz", @nt.contents
    assert_equal "bar", Clipboard.top
  end
  
  def test_paste
    @nt.contents = "foobarbaz"
    @nt.select(3, 6)
    @nt.cut
    assert_equal "foobaz", @nt.contents
    assert_equal "bar", Clipboard.top
    @nt.cursor = 9
    @nt.paste
    assert_equal "foobazbar", @nt.contents
  end
  
  def test_del
    @nt.contents = "foobarbaz"
    @nt.cursor = 6
    5.times { @nt.del }
    assert_equal "foobar", @nt.contents
    @nt.contents = "foobarbaz"
    @nt.select(0, 9)
    @nt.del
    assert_equal "", @nt.contents
  end
  
  def test_undo_del
    @nt = Redcar.new_tab
    @nt.focus
    @nt.contents = "foobarbaz"
    @nt.cursor = 6
    assert_equal 6, @nt.cursor_offset
    @nt.del
    assert_equal "foobaraz", @nt.contents
    assert_equal 6, @nt.cursor_offset
    @nt.undo
    assert_equal "foobarbaz", @nt.contents
    assert_equal 6, @nt.cursor_offset
  end
  
  def test_backspace
    @nt.contents = "foobarbaz"
    @nt.cursor = 3
    5.times { @nt.backspace }
    assert_equal "barbaz", @nt.contents
    @nt.contents = "foobarbaz"
    @nt.select(0, 9)
    @nt.backspace
    assert_equal "", @nt.contents
  end
  
  def test_get_line
    @nt.contents = "foo\nbar\nbaz"
    assert_equal "foo\n", @nt.get_line(0)
    assert_equal "bar\n", @nt.get_line(1)
    assert_equal "baz",   @nt.get_line(2)
    assert_equal nil,     @nt.get_line(100)
    assert_equal "baz",   @nt.get_line(-1)
    assert_equal "bar\n", @nt.get_line(-2)
    assert_equal "foo\n", @nt.get_line(-3)
    assert_equal nil, @nt.get_line(-4)
    assert_equal nil, @nt.get_line(-10)
    @nt.cursor = 2
    assert_equal "foo\n", @nt.get_line
    @nt.cursor = 10
    assert_equal "baz", @nt.get_line
  end
  
  def test_get_lines
    @nt.contents = "foo\nbar\nbaz"
    assert_equal ["foo\n"], @nt.get_lines([0])
    assert_equal [],        @nt.get_lines([])
    assert_equal ["foo\n", "bar\n"], @nt.get_lines([0, 1])
    
    assert_equal ["foo\n"], @nt.get_lines(0..0)
    assert_equal ["foo\n", "bar\n", "baz"], @nt.get_lines(0..2)
    assert_equal ["foo\n", "bar\n", "baz"], @nt.get_lines(0..-1)
  end
  
  def test_replace_selection
    @nt.contents = "foo\nbar\nbaz"
    @nt.select(0, 3)
    assert_equal [0, 3], @nt.selection_bounds
    
    @nt.replace_selection{|text| text.upcase}
    
    assert_equal "FOO\nbar\nbaz", @nt.contents
    assert_equal [0, 3], @nt.selection_bounds
    
    @nt.replace_selection "qux"
    
    assert_equal "qux\nbar\nbaz", @nt.contents
    assert_equal [0, 3], @nt.selection_bounds
    
    @nt.replace_selection ""
    
    assert_equal "\nbar\nbaz", @nt.contents
    assert_equal [0, 0], @nt.selection_bounds
    assert !@nt.selected?
  end
end
