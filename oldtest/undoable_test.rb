

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestUndoable < Test::Unit::TestCase
  def setup
  end
  def teardown
  end
  
  class TestUndoableArray
    include Redcar::Undoable
    
    attr_accessor :rep
    
    def initialize(arr=[])
      @rep = arr
    end
    
    def append(a)
      to_undo :delete_last
      @rep << a
    end
    
    def delete_last
      @rep = @rep[0..-2]
    end
  end
  
  def test_undo
    tu = TestUndoableArray.new
    tu.append(3)
    assert_equal [3], tu.rep
    tu.undo
    assert_equal [], tu.rep
  end
  
  # clear undo was at one point screwing stuff up
  def test_clear_undo
    tu = TestUndoableArray.new
    tu.append(3)
    tu.undo
    assert_equal [], tu.rep
    tu.clear_undo
    tu.append(3)
    tu.undo
    assert_equal [], tu.rep
  end
end
