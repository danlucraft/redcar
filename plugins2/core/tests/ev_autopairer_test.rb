
require File.dirname(__FILE__) + '/ev_parser_test'

module Redcar::Tests
  class AutoPairerTests < Test::Unit::TestCase
    def setup
      @grammar = Redcar::EditView::Grammar.grammar(:name => 'Ruby')
      sc = Redcar::EditView::Scope.new(:pattern => @grammar,
                                       :grammar => @grammar,
                                       :start => TextLoc(0, 0))
      @buf = Gtk::SourceBuffer.new
      @parser = Redcar::EditView::Parser.new(@buf, sc, [@grammar])
      @parser.parse_all = true
      @autopairer = Redcar::EditView::AutoPairer.new(@buf, @parser)
      @old_pref1 = Redcar::Preference.get("Editing/Indent size")
      @old_pref2 = Redcar::Preference.get("Editing/Use spaces instead of tabs")
      Redcar::Preference.set("Editing/Indent size", 1)
      Redcar::Preference.set("Editing/Use spaces instead of tabs", false)
    end
    
    def teardown
      Redcar::Preference.set("Editing/Indent size", @old_pref1)
      Redcar::Preference.set("Editing/Use spaces instead of tabs", @old_pref2)
    end
    
    def test_inserts_pair_end
      @buf.text = "pikon"
      @buf.place_cursor(@buf.line_end1(0))
      @buf.insert_at_cursor("(")
      assert_equal "pikon()", @buf.text
      assert_equal 6, @buf.cursor_offset
      assert_equal 1, @autopairer.mark_pairs.length
    end
    
    def test_delete_pair_start
      @buf.text = "pikon"
      @buf.place_cursor(@buf.line_end1(0))
      @buf.insert_at_cursor("(")
      assert_equal "pikon()", @buf.text
      @buf.delete(@buf.iter(5), @buf.iter(6))
      assert_equal "pikon", @buf.text
      assert_equal 5, @buf.cursor_offset
      assert_equal 0, @autopairer.mark_pairs.length
    end
    
    def test_typover_end
      @buf.text = "pikon"
      @buf.place_cursor(@buf.line_end1(0))
      @buf.insert_at_cursor("(")
      @buf.insert_at_cursor("h")
      @buf.insert_at_cursor("i")
      @buf.insert_at_cursor(")")
      assert_equal "pikon(hi)", @buf.text
      assert_equal 9, @buf.cursor_offset
      assert_equal 0, @autopairer.mark_pairs.length
    end
    
    def test_navigate_outside_brackets
      @buf.text = "pikon"
      @buf.place_cursor(@buf.line_end1(0))
      @buf.insert_at_cursor("(")
      @buf.insert_at_cursor("h")
      @buf.place_cursor(@buf.line_start(0))
      @buf.place_cursor(@buf.iter(7))
      @buf.insert_at_cursor(")")
      assert_equal "pikon(h))", @buf.text
      assert_equal 8, @buf.cursor_offset
      assert_equal 0, @autopairer.mark_pairs.length
    end
    
    def type(text, buffer)
      text.split(//).each do |char|
        buffer.insert_at_cursor(char)
      end
    end
    
    def backspace(buffer)
      buffer.delete(buffer.iter(buffer.cursor_offset-1),
                    buffer.cursor_iter)
    end
  end
end
