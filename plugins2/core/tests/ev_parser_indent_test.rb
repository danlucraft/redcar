
module Redcar::Tests
  class ParserIndentTests < Test::Unit::TestCase
    def setup
      @grammar = Redcar::EditView::Grammar.grammar(:name => 'Ruby')
      sc = Redcar::EditView::Scope.new(:pattern => @grammar,
                                       :grammar => @grammar,
                                       :start => TextLoc(0, 0))
      @buf = Gtk::SourceBuffer.new
      @parser = Redcar::EditView::Parser.new(@buf, sc, [@grammar])
      @parser.parse_all = true
    end
    
    def test_indent_delta_no_changes
      @buf.insert @buf.iter(0), "foo\nbar\nbaz\n"
      assert_equal 0, @parser.indent_delta(1)
    end
    
    def test_indent_delta_plus_one
      @buf.insert @buf.iter(0), "foo\nclass Foo\nbaz\n"
      assert_equal 1, @parser.indent_delta(2)
    end
    
    def test_indent_delta_plus_two
      @buf.insert @buf.iter(0), "foo\nclass Foo module Bar\nbaz\n"
      assert_equal 1, @parser.indent_delta(2)
    end
    
    def test_indent_delta_minus_one
      @buf.insert @buf.iter(0), "class Foo\nend\nfoo"
      assert_equal -1, @parser.indent_delta(2)
    end
    
    def test_indent_delta_minus_one_at_zero
      @buf.insert @buf.iter(0), "end\nfoo"
      assert_equal -1, @parser.indent_delta(1)
    end
  end
end
