
require 'test/unit'
require File.dirname(__FILE__) + '/undoable'

class TestUndo < Test::Unit::TestCase
  
  class UndoableObject
    include Undoable
    
    attr_accessor :state
    
    def initialize
      @state = []
    end
    
    def append(obj)
      to_undo :pop
      @state << obj
    end
    
    def pop
      rv = @state.pop
      to_undo :append, rv
      rv
    end
    
    def append_123
      undoable do
        append(1)
        append(2)
        append(3)
      end
    end
    
    def append_arr(arr)
      to_undo :remove_arr, arr.length
      @state += arr
    end
    
    def remove_arr(num)
      to_undo :append_arr, @state[-num..-1]
      @state = @state[0..(-num-1)]
    end
    
    def sort
      c = @state.clone
      to_undo do
        @state = c
      end
      @state = @state.sort
    end
    
    undo_composable do |a, b|
      if a.method_name == :append_arr and 
          b.method_name == :append_arr
        UndoItem.new(:append_arr, [b.args[0]+a.args[0]])
      end
    end
    
    undo_composable do |a, b|
      if a.method_name == :remove_arr and
          b.method_name == :remove_arr
        UndoItem.new(:remove_arr, [a.args[0]+b.args[0]])
      end
    end
  end
  
  def test_undoes
    uo = UndoableObject.new
    uo.append(1)
    uo.undo
    assert_equal [], uo.state
  end
  
  def test_undoes2
    uo = UndoableObject.new
    uo.append(1)
    uo.append(2)
    uo.append(3)
    uo.pop
    uo.undo
    assert_equal [1, 2, 3], uo.state
  end
  
  def test_high_level_undo_action
    uo = UndoableObject.new
    uo.append_123
    uo.undo
    assert_equal [], uo.state
  end
  
  def test_undoes_composable1
    uo = UndoableObject.new
    uo.append_arr([1, 2, 3])
    uo.append_arr([10, 20, 30])
    uo.undo
    assert_equal [], uo.state
  end
  
  def test_undoes_composable2
    uo = UndoableObject.new
    uo.append_arr([1, 2, 3, 4, 5, 6, 7, 8])
    uo.remove_arr(2)
    uo.remove_arr(3)
    assert_equal [1, 2, 3], uo.state
    uo.undo
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8], uo.state
  end
  
  def test_undoes_tiny
    uo = UndoableObject.new
    uo.append_123
    uo.undo_tiny
    assert_equal [1, 2], uo.state
  end
  
  def test_undo_chaining
    uo = UndoableObject.new
    10.times do |i|
      uo.append(i)
    end
    3.times { uo.undo }
    assert_equal (0..6).to_a, uo.state
  end
  
  def test_undo_chaining_is_like_emacs
    uo = UndoableObject.new
    10.times do |i|
      uo.append(i)
    end
    6.times do
      uo.undo
    end
    assert_equal (0..3).to_a, uo.state
    uo.append(:a)
    7.times do 
      uo.undo
    end
    assert_equal (0..9).to_a, uo.state
  end
  
  def test_undo_chaining_is_like_emacs2
    uo = UndoableObject.new
    uo.append(:a)
    uo.append(:b)
    2.times { uo.undo }
    uo.append(1)
    3.times { uo.undo }
    assert_equal [:a, :b], uo.state
  end
  
  def test_undoable_block
    uo = UndoableObject.new
    uo.append_arr([2, 3, 1, 5, 4])
    uo.sort
    assert_equal [1, 2, 3, 4, 5], uo.state
    uo.undo
    assert_equal [2, 3, 1, 5, 4], uo.state
  end
end
