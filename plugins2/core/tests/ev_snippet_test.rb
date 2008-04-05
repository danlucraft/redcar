
require File.dirname(__FILE__) + '/ev_parser_test'

module Redcar::Tests
  class SnippetTests < Test::Unit::TestCase
    SnippetInserter = Redcar::EditView::SnippetInserter
    def setup
      @grammar = Redcar::EditView::Grammar.grammar(:name => 'Ruby')
      sc = Redcar::EditView::Scope.new(:pattern => @grammar,
                                       :grammar => @grammar,
                                       :start => TextLoc(0, 0))
      @buf = Gtk::SourceBuffer.new
      sc.set_start_mark @buf, 0, true
      sc.set_end_mark   @buf, @buf.char_count, false
      sc.set_open(true)
      @parser = Redcar::EditView::Parser.new(@buf, sc, [@grammar])
      @parser.parse_all = true
      @snippet_inserter = SnippetInserter.new(@buf)
    end
    
    def teardown
    end

    def type(text, buffer)
      if buffer.selection?
        range = buffer.selection_range
        buffer.delete(buffer.iter(range.first),
                      buffer.iter(range.last))
      end
      text.split(//).each do |char|
        buffer.insert_at_cursor(char)
      end
    end
    
    def backspace(buffer)
      buffer.delete(buffer.iter(buffer.cursor_offset-1),
                    buffer.cursor_iter)
    end
    
    def press_tab
      Redcar::StandardMenus::Tab.new(@snippet_inserter, @buf).do
    end
    
    def press_shift_tab
      Redcar::StandardMenus::ShiftTab.new(@snippet_inserter, @buf).do
    end
    
    def test_inserts_plain_content
      SnippetInserter.register("source.ruby - string - comment",
                               "DBL",
                               "Daniel Benjamin Lucraft")
      @buf.text=("DBL")
      press_tab
      assert_equal "Daniel Benjamin Lucraft", @buf.text
      assert_equal 23, @buf.cursor_offset
    end

    def test_inserts_one_tab_stop
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t\nend")
      @buf.text=("testsnip")
      press_tab
      source1="if \n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 3, @buf.cursor_offset
    end

    def test_allows_tabbing_past_snippet
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t\nend")
      @buf.text=("testsnip")
      press_tab
      press_tab
      source1="if \n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 9, @buf.cursor_offset
      assert !@snippet_inserter.in_snippet?
    end

    def test_allows_tabbing_between_tab_stops
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t$2\nend")
      @buf.text=("testsnip")
      press_tab
      press_tab
      source1="if \n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 5, @buf.cursor_offset
      press_tab
      assert_equal source1, @buf.text
      assert_equal 9, @buf.cursor_offset
      assert !@snippet_inserter.in_snippet?
    end

    def test_allows_typing_and_tabbing
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t$2\nend")
      @buf.text=("testsnip")
      press_tab
      type("Pegasus", @buf)
      press_tab
      source1="if Pegasus\n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 12, @buf.cursor_offset
      type("Cain", @buf)
      press_tab
      source2="if Pegasus\n\tCain\nend"
      assert_equal source2, @buf.text
      assert_equal 20, @buf.cursor_offset
      assert !@snippet_inserter.in_snippet?
    end

    def test_allows_shift_tabbing
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t$2\nend")
      @buf.text=("testsnip")
      press_tab
      type("Pegasus", @buf)
      press_tab
      source1="if Pegasus\n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 12, @buf.cursor_offset
      type("Cain", @buf)
      press_shift_tab
      assert_equal 3..10, @buf.selection_range
      type("Viper", @buf)
      source3="if Viper\n\tCain\nend"
      assert_equal source3, @buf.text
      assert_equal 8, @buf.cursor_offset
      assert @snippet_inserter.in_snippet?
    end
    
    def test_inserts_tab_stop_content
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if ${1:condition}\n\t$0\nend")
      @buf.text=("testsnip")
      press_tab
      source1="if condition\n\t\nend"
      assert_equal source1, @buf.text
      assert_equal 3..12, @buf.selection_range
    end

    def test_leaves_snippet_on_cursor_move
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if ${1:condition}\n\t$0\nend")
      @buf.text=("testsnip")
      press_tab
      assert @snippet_inserter.in_snippet?
      @buf.place_cursor(@buf.line_start(0))
      assert !@snippet_inserter.in_snippet?
    end
    
    def test_multiple_stops_with_content
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if ${1:condition}\n\t${2:code}\nend")
      @buf.text=("testsnip")
      press_tab
      source1="if condition\n\tcode\nend"
      assert_equal source1, @buf.text
      assert_equal 3..12, @buf.selection_range
      press_tab
      source1="if condition\n\tcode\nend"
      assert_equal source1, @buf.text
      assert_equal 14..18, @buf.selection_range
      press_tab
      assert_equal source1, @buf.text
      assert_equal 22, @buf.cursor_offset
      assert !@snippet_inserter.in_snippet?
    end

    def test_mirrors_mirror_text
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "name: $1\nname: $1")
      @buf.text=("testsnip")
      press_tab
      assert_equal "name: \nname: ", @buf.text
      assert_equal 6..6, @buf.selection_range
      type("raider", @buf)
      assert_equal "name: raider\nname: raider", @buf.text
      assert_equal 12..12, @buf.selection_range
      3.times { backspace(@buf) }
      assert_equal "name: rai\nname: rai", @buf.text
      assert_equal 9..9, @buf.selection_range
    end
    
    def test_mirrors_mirror_stop_with_content
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "name: ${1:leoban}\nname: $1")
      @buf.text=("testsnip")
      press_tab
      assert_equal "name: leoban\nname: leoban", @buf.text
      assert_equal 6..12, @buf.selection_range
    end
    
    def test_transformations
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "name: $1\nupper: ${1/(\\w+)/\\U$1\\E/}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "name: \nupper: ", @buf.text
      assert_equal 6..6, @buf.selection_range
      type("raptor", @buf)
      assert_equal "name: raptor\nupper: RAPTOR", @buf.text
      assert_equal 12..12, @buf.selection_range
      3.times { backspace(@buf) }
      assert_equal "name: rap\nupper: RAP", @buf.text
      assert_equal 9..9, @buf.selection_range
      # test not global:
      type(" blackbird", @buf)
      assert_equal "name: rap blackbird\nupper: RAP blackbird", @buf.text
      assert_equal 19..19, @buf.selection_range
    end
    
    def test_global_transformations
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "name: $1\nupper: ${1/(\\w+)/\\U$1\\E/g}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "name: \nupper: ", @buf.text
      assert_equal 6..6, @buf.selection_range
      type("raptor blackbird", @buf)
      assert_equal "name: raptor blackbird\nupper: RAPTOR BLACKBIRD", @buf.text
      assert_equal 22..22, @buf.selection_range
    end
    
    def test_nested_tab_stops
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               ':${1:key} => ${2:"${3:value}"}${4:, }')
      @buf.text=("testsnip")
      press_tab
      assert_equal ":key => \"value\", ", @buf.text
      assert_equal 1..4, @buf.selection_range
      press_tab
      assert_equal 8..15, @buf.selection_range
      press_tab
      assert_equal 9..14, @buf.selection_range
      type("virgon", @buf)
      assert_equal ":key => \"virgon\", ", @buf.text
      assert_equal 15..15, @buf.selection_range
      press_shift_tab
      assert_equal 8..16, @buf.selection_range
    end
    
    def test_super_nested_tab_stops
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               ':${1:key} => ${2:"${3:value ${4:is} 3}"}${5:, }')
      @buf.text=("testsnip")
      press_tab
      assert_equal ":key => \"value is 3\", ", @buf.text
      assert_equal 1..4, @buf.selection_range
      press_tab
      assert_equal 8..20, @buf.selection_range
      press_tab
      assert_equal 9..19, @buf.selection_range
      press_tab
      assert_equal 15..17, @buf.selection_range
    end
  end
end
