
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
      @ap = Redcar::EditView::AutoPairer.new(@buf, @parser)
    end

    def teardown
      Redcar.win.tabs.each &:close
    end

    def type(text, buffer=@buf)
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

    def press_tab(si=@snippet_inserter, buf=@buf)
      Redcar::StandardMenus::Tab.new(si, buf).do
    end

    def press_shift_tab(si=@snippet_inserter, buf=@buf)
      Redcar::StandardMenus::ShiftTab.new(si, buf).do
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

    def test_escapes_dollars
      SnippetInserter.register("source.ruby - string - comment",
                               "DBL",
                               "Daniel \\$1 Benjamin Lucraft")
      @buf.text=("DBL")
      press_tab
      assert_equal "Daniel $1 Benjamin Lucraft", @buf.text
      assert_equal 26, @buf.cursor_offset
    end

    def test_inserts_environment_variable
      tab = Redcar.win.new_tab(Redcar::EditTab)
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "Felix ${TM_LINE_INDEX} Gaeta")
      doc = tab.document
      doc.text=("CoS testsnip")
      press_tab(tab.view.snippet_inserter, doc)
      assert_equal "CoS Felix 4 Gaeta", doc.text
      assert_equal 17, doc.cursor_offset
      tab.close
    end

    def test_inserts_environment_variable2
      tab = Redcar.win.new_tab(Redcar::EditTab)
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "Felix $TM_LINE_INDEX Gaeta")
      doc = tab.document
      doc.text=("CoS testsnip")
      press_tab(tab.view.snippet_inserter, doc)
      assert_equal "CoS Felix 4 Gaeta", doc.text
      assert_equal 17, doc.cursor_offset
      tab.close
    end

    def test_transforms_environment_variable
      tab = Redcar.win.new_tab(Redcar::EditTab)
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "Felix ${TM_CURRENT_LINE/Co/ChiefOfStaff/} Gaeta")
      doc = tab.document
      doc.text=("CoS testsnip")
      press_tab(tab.view.snippet_inserter, doc)
      assert_equal "CoS Felix ChiefOfStaffS  Gaeta", doc.text
      assert_equal 30, doc.cursor_offset
      tab.close
    end

    def test_transforms_environment_variable_global
      # also tests escaping of slashes in transform
      tab = Redcar.win.new_tab(Redcar::EditTab)
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "Felix ${TM_CURRENT_LINE/\\w/C\\/S/g} Gaeta")
      doc = tab.document
      doc.text=("CoS testsnip")
      press_tab(tab.view.snippet_inserter, doc)
      assert_equal "CoS Felix C/SC/SC/S  Gaeta", doc.text
      assert_equal 26, doc.cursor_offset
      tab.close
    end

    def test_inserts_one_tab_stop
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t\nend")
      @buf.text=("testsnip")
      press_tab
      assert_equal "if \n\t\nend", @buf.text
      assert_equal 3, @buf.cursor_offset
    end

    def test_selects_tab_stop_zero
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if ${0:instance}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "if instance", @buf.text
      assert_equal 3..11, @buf.selection_range
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

    def test_allows_tabbing_between_nonconsecutive_tab_stops
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "if $1\n\t$3\nend")
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

    def test_inserts_environment_variable_as_placeholder
      tab = Redcar.win.new_tab(Redcar::EditTab)
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "Felix ${1:$TM_LINE_INDEX} Gaeta")
      doc = tab.document
      doc.text=("CoS testsnip")
      press_tab(tab.view.snippet_inserter, doc)
      assert_equal "CoS Felix 4 Gaeta", doc.text
      assert_equal 11, doc.cursor_offset
      tab.close
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

    def test_mirrors_mirror_both_with_content
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               "name: ${1:leoban}\nname: ${1:leoban}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "name: leoban\nname: leoban", @buf.text
      assert_equal 6..12, @buf.selection_range
      type("adama", @buf)
      assert_equal "name: adama\nname: adama", @buf.text
      assert_equal 11..11, @buf.selection_range
      3.times { backspace(@buf) }
      assert_equal "name: ad\nname: ad", @buf.text
      assert_equal 8..8, @buf.selection_range
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

    def test_latex_snippet
    SnippetInserter.register("source.ruby - string - comment",
                             "testsnip",
                             "\\\\begin{${1:env}}\n\t${1/(enumerate|itemize|list)|(description)|.*/(?1:\\item )(?2:\\item)/}$0\n\\\\end{${1:env}}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "\\begin{env}\n\t\n\\end{env}", @buf.text
      assert_equal 7..10, @buf.selection_range
      type("list", @buf)
      assert_equal "\\begin{list}\n\t\\item \n\\end{list}", @buf.text
      assert_equal 11..11, @buf.selection_range
      press_tab
      assert_equal 20..20, @buf.selection_range
    end

    def test_transformations_do_not_move_cursor
      SnippetInserter.register("source.ruby - string - comment",
        "testsnip",
        "def $1${1/.+/\"\"\"/}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "def ", @buf.text
      assert_equal 4, @buf.cursor_offset
      type "a"
      assert_equal "def a\"\"\"", @buf.text
      assert_equal 5, @buf.cursor_offset
    end

    def test_abutting_dollars
      SnippetInserter.register("source.ruby - string - comment",
        "testsnip",
        "def ${1:fname} ${3:docstring for $1}${3/.+/\"\"\"\\n/}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "def fname docstring for fname\"\"\"\n", @buf.text
      assert_equal 4..9, @buf.selection_range
      @buf.delete_selection
      assert_equal 4..4, @buf.selection_range
      assert_equal "def  docstring for \"\"\"\n", @buf.text
    end

    def test_abutting_dollars2
      SnippetInserter.register("source.ruby - string - comment",
        "testsnip",
        "def ${1:fname} ${3:docstring for $1}${3/.+/\"\"\"\\n/}${3/.+/\\t/}${0:pass}")
      @buf.text=("testsnip")
      press_tab
      assert_equal "def fname docstring for fname\"\"\"\n\tpass", @buf.text
      assert_equal 4..9, @buf.selection_range
      @buf.delete_selection
      assert_equal 4..4, @buf.selection_range
      assert_equal "def  docstring for \"\"\"\n\tpass", @buf.text
      puts "TYPING M"
      type "m"
      assert_equal 5..5, @buf.selection_range
      assert_equal "def m docstring for m\"\"\"\n\tpass", @buf.text
      press_tab
      assert_equal 6..21, @buf.selection_range
      puts "TYPING A"
      type("a")
      assert_equal "def m a\"\"\"\n\tpass", @buf.text
      assert_equal 7, @buf.cursor_offset
      puts "TYPING B"
      type("b")
      assert_equal "def m ab\"\"\"\n\tpass", @buf.text
      puts "TYPING C"
      type("c")
      assert_equal "def m abc\"\"\"\n\tpass", @buf.text
    end

    def test_executes_shell_commands
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
                               'Date:`date +%Y-%m-%d`')
      @buf.text=("testsnip")
      press_tab

      assert_equal "Date:#{Time.now.strftime("%Y-%m-%d")}", @buf.text
      assert_equal 15..15, @buf.selection_range
    end

    def test_executes_shell_commands_with_support
      SnippetInserter.register("source.ruby - string - comment",
                               "testsnip",
      "assert_equal`snippet_paren.rb`${1:expected}, ${0:actual}`snippet_paren.rb end`")
      @buf.text=("testsnip")
      press_tab

      assert_equal "assert_equal(expected, actual)", @buf.text
      assert_equal 13..21, @buf.selection_range
    end
  end
end
