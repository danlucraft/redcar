
require 'mocha'

module Redcar::Tests
  class ParserTests < Test::Unit::TestCase
    def setup
      @buf  = Gtk::SourceBuffer.new
      @gr   = Redcar::EditView.grammar(:name => "Ruby")
      @root = Redcar::EditView::Scope.new(:pattern => @gr,
                                         :grammar => @gr,
                                         :start => Redcar::EditView::TextLoc.new(0, 0))
      @parser = Redcar::EditView::Parser.new(@buf, @root)
    end
    
    def test_signals_connected1
      @parser.expects(:store_insertion)
      @buf.insert(@buf.iter(0), "hi")
    end
    
    def test_signals_connected2
      @parser.expects(:process_changes)      
      @buf.insert(@buf.iter(0), "hi")
    end
    
    def test_inserts_a_line_from_nothing
      @buf.insert(@buf.iter(0), "class < Red")
      assert_equal 3, @root.children.length
    end
    
    def test_inserts_a_couple_of_lines_from_nothing
      @buf.insert(@buf.iter(0), "class < Red\nend")
      assert_equal 4, @root.children.length
    end
    
    def test_inserts_a_line_between_two_lines
      @buf.insert(@buf.iter(0), "class < Red\nend")
      @buf.insert(@buf.iter(12), "def foo\n")
      assert_equal 5, @root.children.length
    end
    
    def test_inserts_a_symbol_into_a_line
      @buf.insert(@buf.iter(0), "puts()")
      @buf.insert(@buf.iter(5), ":symbol")
      assert_equal 3, @root.children.length
    end
    
    def test_deletes_a_symbol_from_a_line
      @buf.insert(@buf.iter(0), "puts(:symbol)")
      @buf.delete(@buf.iter(5), @buf.iter(12))
      assert_equal "puts()", @buf.text
      assert_equal 2, @root.children.length
    end
    
    def test_deletes_a_whole_line
      @buf.insert(@buf.iter(0), "class < Red\ndef foo\nend")
      @buf.delete(@buf.iter(12), @buf.iter(20))
      puts @root.pretty
      assert_equal 4, @root.children.length
    end
  end
end
