
require File.dirname(__FILE__) + '/ev_parser_test'

module Redcar::Tests
  class IndenterTests < Test::Unit::TestCase
    def setup
      @grammar = Redcar::EditView::Grammar.grammar(:name => 'Ruby')
      sc = Redcar::EditView::Scope.new(:pattern => @grammar,
                                       :grammar => @grammar,
                                       :start => TextLoc(0, 0))
      @buf = Gtk::SourceBuffer.new
      @parser = Redcar::EditView::Parser.new(@buf, sc, [@grammar])
      @parser.parse_all = true
      @indenter = Redcar::EditView::Indenter.new(@buf, @parser)
      @old_pref1 = Redcar::Preference.get("Editing/Indent size")
      @old_pref2 = Redcar::Preference.get("Editing/Use spaces instead of tabs")
      Redcar::Preference.set("Editing/Indent size", 1)
      Redcar::Preference.set("Editing/Use spaces instead of tabs", false)
    end

    def teardown
      Redcar::Preference.set("Editing/Indent size", @old_pref1)
      Redcar::Preference.set("Editing/Use spaces instead of tabs", @old_pref2)
    end
    
    def test_no_indent_on_first_line
      @buf.text = "puts 'hi'"
      @indenter.indent_line(0)
      assert_equal "puts 'hi'", @buf.text
    end
    
    def test_follows_previous_line_tabs
      @buf.text = "\tputs 'hi'\n1+2"
      @indenter.indent_line(1)
      assert_equal "\tputs 'hi'\n\t1+2", @buf.text
    end
    
    def test_follows_previous_line_spaces
      @buf.text = "  puts 'hi'\n1+2"
      @indenter.indent_line(1)
      assert_equal "  puts 'hi'\n  1+2", @buf.text
    end
    
    def test_increases_on_increasePattern
      @buf.text = "\tdef foo\np :asdf"
      @indenter.indent_line(1)
      assert_equal "\tdef foo\n\t\tp :asdf", @buf.text
    end
    
    def test_decreases_on_decreasePattern
      @buf.text = "\tdef foo\n\t\tp :asdf\nend"
      @indenter.indent_line(2)
      assert_equal "\tdef foo\n\t\tp :asdf\n\tend", @buf.text
    end
    
    def test_indents_next_line
      buf, parser = ParserTests.clean_parser_and_buffer('C')
      indenter = Redcar::EditView::Indenter.new(buf, parser)
      buf.text = "\tint i;\n\tif (foo)\nputs(\"\");"
      indenter.indent_line(2)
      assert_equal "\tint i;\n\tif (foo)\n\t\tputs(\"\");", buf.text
    end
    
    def test_indents_only_next_line
      buf, parser = ParserTests.clean_parser_and_buffer('C')
      indenter = Redcar::EditView::Indenter.new(buf, parser)
      buf.text = "\tint i;\n\tif (foo)\n\t\tputs(\"\");\n\t\tputs(\"asdf\");"
      indenter.indent_line(3)
      assert_equal "\tint i;\n\tif (foo)\n\t\tputs(\"\");\n\tputs(\"asdf\");", buf.text
    end
    
    def test_unindented_line
      buf, parser = ParserTests.clean_parser_and_buffer('C')
      indenter = Redcar::EditView::Indenter.new(buf, parser)
      buf.text = "\tint i;\n\t#define FOO 1"
      indenter.indent_line(1)
      assert_equal "\tint i;\n#define FOO 1", buf.text
    end
    
    def test_returns_to_normal_after_unindented_line
      buf, parser = ParserTests.clean_parser_and_buffer('C')
      indenter = Redcar::EditView::Indenter.new(buf, parser)
      buf.text = "\tint i;\n#define FOO 1\nint i;\nint j;"
      indenter.indent_line(2)
      indenter.indent_line(3)
      assert_equal "\tint i;\n#define FOO 1\n\tint i;\n\tint j;", buf.text
    end

    # This is a tough test to pass, but you should come back to it
    def test_returns_to_normal_after_unindented_and_next
      p :please_implement_indent_returns_to_normal_after_unindented_and_next
#       buf, parser = ParserTests.clean_parser_and_buffer('C')
#       indenter = Redcar::EditView::Indenter.new(buf, parser)
#       buf.text = "\tint i;\n\tif (fo)\n\t\tputs(\"\");\n#define FOO 1\nint i;"
#       indenter.indent_line(4)
#       assert_equal "\tint i;\n\tif (fo)\n\t\tputs(\"\");#define FOO 1\n\tint i;", buf.text
    end
    
    def test_inserts_newline_if_line_only_contains_ending_scope
      buf, parser = ParserTests.clean_parser_and_buffer('C')
      indenter = Redcar::EditView::Indenter.new(buf, parser)
      buf.text = "void main() {}"
      buf.place_cursor(buf.iter(13))
      buf.insert_at_cursor("\n")
      assert_equal "void main() {\n\t\n}", buf.text
    end
  end
end
