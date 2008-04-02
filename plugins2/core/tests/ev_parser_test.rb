
require 'mocha'
require File.dirname(__FILE__) + '/ev_grammar_test'

module Redcar::Tests
  class ParserTests < Test::Unit::TestCase
    def self.clean_parser_and_buffer(grh)
      if grh.is_a? Redcar::EditView::Grammar
        gr = grh
      elsif grh.is_a? String
        gr = Redcar::EditView::Grammar.grammar(:name => grh)
      else
        gr = Redcar::EditView::Grammar.new(grh)
      end
      buf = Gtk::SourceBuffer.new
      sc = Redcar::EditView::Scope.new(:pattern => gr,
                                       :grammar => gr,
                                       :start => TextLoc(0, 0))
      sc.set_start_mark buf, 0, true
      sc.set_end_mark   buf, buf.char_count, false
      smp = Redcar::EditView::Parser.new(buf, sc, [gr])
      smp.parse_all = true
      return buf, smp
    end
    
    def setup
      @buf  = Gtk::SourceBuffer.new
      @gr   = Redcar::EditView::Grammar.grammar(:name => "Ruby")
      @root = Redcar::EditView::Scope.new(:pattern => @gr,
                                          :grammar => @gr,
                                          :start => Redcar::EditView::TextLoc.new(0, 0))
      @root.set_start_mark @buf, 0, true
      @root.set_end_mark   @buf, @buf.char_count, false
      @parser = Redcar::EditView::Parser.new(@buf, @root)
      
      # stuff for old tests
      @ruby_grammar = Redcar::EditView::Grammar.grammar(:name => 'Ruby')
      @grammar1 = Redcar::Tests::GrammarTests.example_grammar1
      @grammar2 = Redcar::Tests::GrammarTests.example_grammar2
      @lisp_grammar = Redcar::Tests::GrammarTests.lisp_grammar
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
      assert_equal 4, @root.children.length
    end
    
    # --- old tests ----
    
    def test_parser
      gr = Redcar::EditView::Grammar.new(@grammar1)
      sc = Redcar::EditView::Scope.new(:grammar => gr,
                                       :pattern => gr,
                                       :start   => TextLoc(0, 0))
      buf = Gtk::SourceBuffer.new
      smp = Redcar::EditView::Parser.new(buf, sc, [gr])
      assert smp
      assert_equal "source.untitled", smp.root.name
    end
    
    
    def test_parse_line_with_matches
      line = "asdf asdf if asdf asdf for asdfa asdf"
      grh = { 
        "name" => "Grammar Test",
        "scopeName" => "source.example1",
        "patterns" => [ {"name" => "if", "match" => "\\b(if|for)\\b"} ] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = line
      
      assert_equal "source.example1", smp.root.name
      assert_equal 2, smp.root.children.length
      smp.root.children.each do |cs|
        assert_equal "if", cs.name
        assert_equal 0, cs.children.length
      end
    end
    
    def test_parse_line_with_begin_ends
      line = "asdf asdf if \"asd\\\"f asdf\" for asdfa asdf"
      grh = { 
        "scopeName" => "source.example1",
        "patterns" => [ 
                       { "name" => "if", "match" => "\\b(if|for)\\b"},
                       { "name" => "string", 
                         "begin" => "\"", 
                         "end" => "\"",
                         "patterns" => [{ "name" => 'constant.character.escape.untitled',
                                          "match" => '\\\\.'}]
                       }
                      ] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = line
      
      assert_equal "source.example1", smp.root.name
      assert_equal 3, smp.root.children.length
      assert_equal "if", smp.root.children[0].name
      assert_equal "if", smp.root.children[2].name
      assert_equal "string", smp.root.children[1].name
      assert_equal 1, smp.root.children[1].children.length
      assert_equal "constant.character.escape.untitled", smp.root.children[1].children[0].name
    end
    
    def test_parse_line_with_nested_begin_ends
      line = "asdf [ asdf { asdf asf } asfd asdfa ] asdf"
      grh = { 
        "scopeName" => "source.example1",
        "patterns" => [ 
                       { "name" => "square",
                         "begin" => "\\[", 
                         "end" => "\\]",
                         "patterns" => [{ "name" => 'curly',
                                          "begin" => '\\{',
                                          "end" => "\\}"
                                        }]
                       }
                      ] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = line
      
      assert_equal "source.example1", smp.root.name
      assert_equal 1, smp.root.children.length
      ch0 = smp.root.children[0]
      assert_equal "square", ch0.name
      assert_equal 1, ch0.children.length
      ch1 = ch0.children[0]
      assert_equal "curly", ch1.name
      assert_equal 0, ch1.children.length
    end
    
    def test_parse_line_with_repository
      line = "asd if f [ asdf if asdf { asdf if asf } asfd if asdfa ] asdf if adsf"
      grh = { 
        "scopeName" => "source.example1",
        "repository" => {"if" => {"name" => "keyword.if", "match" => '\bif\b' }},
        "patterns" => [ 
                       { "include" => "#if" },
                       { "name" => "code.collection.array",
                         "begin" => "\\[", 
                         "end" => "\\]",
                         "patterns" => [
                                        { "include" => "#if" },
                                        { "name" => 'code.collection.set',
                                          "begin" => '\\{',
                                          "end" => "\\}",
                                          "patterns" => [{ "include" => "#if" }]
                                        }]
                       }
                      ] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = line
      
      assert_equal 3, smp.root.children.length
      assert_equal "keyword.if", smp.root.children[0].name
      assert_equal 3, smp.root.children[1].children.length
      assert_equal "keyword.if", smp.root.children[1].children[0].name
      assert_equal "code.collection.set", smp.root.children[1].children[1].name
    end
    
    def test_parse_line_with_nesting
      line = "asdf ( asdf ( asdf asf ) asfd asdfa ) asdf"
      grh = { 
        "scopeName" => "source.example1",
        "repository" => {
          "brackets" => { 
            "name" => "code.list",
            "begin" => "\\(",
            "end" => "\\)",
            "patterns" => [{ "include" => "#brackets" }]
          }
        },
        "patterns" => [{ "include" => "#brackets"}] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = line
      
      assert_equal 1, smp.root.children.length
      assert_equal 1, smp.root.children[0].children.length
      assert_equal "code.list", smp.root.children[0].name
      assert_equal "code.list", smp.root.children[0].children[0].name
    end
    
    def test_multiline_parsing
      lines = "asdf ( asdf ( asdf \nasf ) asfd asdfa ) asdf"
      grh = { 
        "scopeName" => "source.example1",
        "repository" => {
          "brackets" => { 
            "name" => "code.list",
            "begin" => "\\(",
            "end" => "\\)",
            "patterns" => [{ "include" => "#brackets" }]
          }
        },
        "patterns" => [{ "include" => "#brackets"}] 
      }
      buf, smp = ParserTests.clean_parser_and_buffer(grh)
      buf.text = lines
      
      assert_equal 1, smp.root.children.length
      assert_equal 1, smp.root.children[0].children.length
    end
    
    def test_parse_text_bug_for_included_base_pattern
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      source=<<HI
require "foobar"
HI
      buf.text = source
      assert_equal 2, smp.root.children[0].children.length
    end
    
    # Parse line should work repeatedly with no ill effects.
    def test_re_parse_line
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"asdf \#{foo} asdf\").last\n  end\nend\n"
      buf.text=(rubycode)
      
      copy = smp.root.pretty2
      10.times { assert smp.parse_line("class Redcar::File\n", 0) }
      assert_equal copy, smp.root.pretty2
    end
    
    # ... even when there are opening scopes in the line
    def test_re_parse_line_with_opening_scopes
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode=<<P1END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P1END
      buf.text=(rubycode)
      copy = smp.root.pretty2
      1.times { assert smp.parse_line("foo=\<\<HI", 1) }
      assert_equal copy, smp.root.pretty2
    end
    
    # ... or closing scopes.
    def test_re_parse_line_with_closing_scopes
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode=<<P2END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P2END
      buf.text=(rubycode)
      
      copy = smp.root.pretty2
      10.times { assert smp.parse_line("HI", 4) }
      assert_equal copy, smp.root.pretty2
    end
    
    # Reparsing should also work ok when there are new things. 
    
    # Like new single scopes ...
    def test_re_parse_line_with_extra_single_scopes
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode=<<P2END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P2END
      buf.text=(rubycode)
      assert_equal 3, smp.root.children.length
      assert smp.parse_line("puts \"hello\", @hello", 0)
      assert_equal 5, smp.root.children.length
    end
    
    # ... and new opening scopes. Here parse_line should return 
    # false to indicate the scope at the end of the line has changed ...
    def test_re_parse_line_with_extra_opening_scopes
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"asdf asdf\").last\n  end\nend\n"
      buf.text=(rubycode)
      
      assert_equal 10, smp.root.children.length
      assert !smp.parse_line("    @filename.split(\"asdf asdf\").last=\<\<HI", 2)
      assert_equal 11, smp.root.children.length # <- this is not up to date for the entire text.
    end
    
    # ... and the same for new closing scopes. 
    def test_re_parse_line_with_extra_closing_scopes
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode=<<APE
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo

puts "hello"
APE
      buf.text=(rubycode)
      
      assert_equal 2, smp.root.children.length
      assert_equal "string.unquoted.heredoc.ruby", smp.root.line_end(4).name
      assert !smp.parse_line("HI", 4)
      assert_equal 2, smp.root.children.length # <- this is not up to date for the entire text.
      assert_equal "source.ruby", smp.root.line_end(4).name
    end
    
    def test_captures_are_children_for_single_scope
      source=<<ENDSTR;
; Here is a comment
(defun hello (x y)
  (+ x y))
ENDSTR
      gr =Redcar::EditView::Grammar.new(@lisp_grammar)
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      buf.text=(source)
      assert_equal "comment.line.semicolon.lisp", smp.root.children[0].name
      assert_equal 1, smp.root.children[0].children.length
      assert_equal "punctuation.definition.comment.lisp", smp.root.children[0].children[0].name
    end
    
    def test_captures_are_children_for_double_scope
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode = "puts \"\#{1+2}\""
      buf.text=(rubycode)
      
      assert_equal 1, smp.root.children.length
      assert_equal "source.ruby.embedded.source", smp.root.children[0].
        children[1].pattern.name
      assert_equal(["punctuation.section.embedded.ruby",
                    "constant.numeric.ruby",
                    "keyword.operator.arithmetic.ruby",
                    "constant.numeric.ruby",
                    "punctuation.section.embedded.ruby"],
                   smp.root.children[0].children[1].children.map{|c| c.name})
    end
    
    def test_begin_and_end_captures_are_children_for_double_scope
      source=<<ENDSTR;
; Here is a comment
(defun hello (x y)
  (+ x y))
(hello "foo" "bar")
ENDSTR
      gr = Redcar::EditView::Grammar.new(@lisp_grammar)
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      buf.text=(source)
      

      assert_equal "string.quoted.double.lisp", smp.root.children[2].name
      assert_equal "string.quoted.double.lisp", smp.root.children[3].name
      assert_equal 2, smp.root.children[2].children.length
      assert_equal 2, smp.root.children[3].children.length
      assert_equal "punctuation.definition.string.begin.lisp", smp.root.children[2].children[0].name
      assert_equal "punctuation.definition.string.end.lisp", smp.root.children[2].children[1].name
      assert_equal(smp.root.children[2].children[1].end, 
                   smp.root.children[2].end)
    end
    
    def test_lisp_grammar
      source=<<ENDSTR;
(car (1 2 3))
ENDSTR
      gr =Redcar::EditView::Grammar.new(@lisp_grammar)
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      buf.text=(source)

      assert_equal 4, smp.root.children.length
      assert_equal "support.function.lisp", smp.root.children[0].name
      assert_equal "constant.numeric.lisp", smp.root.children[1].name
    end  
    
    def test_ruby_syntax
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)

      rubycode = "class Foo\n  def hello\n    puts \"hello\"\n  end\nend\n"
      buf.text=(rubycode)
      
      
      assert_equal 5, smp.root.children.length
      class_scope = smp.root.children[0]
      assert_equal "meta.class.ruby", class_scope.name
      
      # let's assert that zero length scopes don't exist in the scope tree.
      assert_equal 2, class_scope.children.length
      
      # def is in the right place?
      method_def_scope = smp.root.children[1].children[0]
      assert_equal 2, method_def_scope.start.offset
      assert_equal 5, method_def_scope.end.offset
    end
    
    def test_ruby_syntax2
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend"
      buf.text=(rubycode)

       # check that the "class" and "Redcar::File" are picked up:
      class_scope = smp.root.children[0]
      assert_equal 0, class_scope.children[0].start.offset
      assert_equal 5, class_scope.children[0].end.offset
      assert_equal 6, class_scope.children[1].start.offset
      assert_equal 18, class_scope.children[1].end.offset
    end

    def test_build_closing_regexp
      hash = {
        "scopeName" => "source.example1",
        "patterns" => [ 
                       { "name" => "text.heredoc",
                         "begin" => "=<<(\\w+):(\\w+)$", 
                         "end" => '^\1,\2$'
                       }
                      ] 
      }
      
      gr =Redcar::EditView::Grammar.new(hash)
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      md = gr.pattern("text.heredoc").begin.match("text=\<\<END:FOR")
      assert_equal "^END,FOR$", smp.build_closing_regexp(gr.pattern("text.heredoc"), md)
    end
    
    def test_insert_text_in_line_that_contains_an_opening_scope
      source=<<HILL
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
HILL
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      buf.text=(source)
      
      assert_equal 3, smp.root.children.length
      assert smp.root.children[1].end # heredoc is closed
      
      buf.insert(buf.line_start(1), "a;")
      
      assert_equal 4, smp.root.children.length
      assert smp.root.children[1].end # heredoc is closed
    end
    
    def test_insert_text_in_line_that_appends_a_scope
      gr = @ruby_grammar
      buf, smp = ParserTests.clean_parser_and_buffer(gr)
      rubycode=<<SRC1
class Redcar::File
  def nice_name
    @filename.split(\"/\").last
  end
end
SRC1
    buf.text=(rubycode)
    
    assert_equal 10, smp.root.children.length
    
    buf.insert(buf.iter(buf.line_end(2).offset-1), "(\"asdf\")")
                    assert_equal 13, smp.root.children.length
                  end

def test_insert_text_in_line_that_prepends_a_scope
  gr = @ruby_grammar
  buf, smp = ParserTests.clean_parser_and_buffer(gr)
  rubycode=<<SRC1
class Redcar::File
  def nice_name
    @filename.split(\"/\").last
  end
end
SRC1
    buf.text=(rubycode)
    
    assert_equal 10, smp.root.children.length
    
    buf.insert(buf.iter(buf.line_start(2).offset+4), "@thing ")
    assert_equal 11, smp.root.children.length
  end
  
  def test_insert_text_in_line_that_adds_an_opening_scope
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)

    rubycode=<<SRC1
class Redcar::File
  def nice_name
    @filename.split(\"/\").last
  end
end
SRC1
    buf.text=(rubycode)
    
    assert_equal 10, smp.root.children.length
    
    buf.insert(buf.line_end1(2), "=\<\<HI")
    
    assert_equal 9, smp.root.children.length
    assert_equal "string.unquoted.heredoc.ruby", smp.root.children.last.name
  end

  def test_insert_text_in_line_that_adds_a_closing_scope
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode=<<CRALL
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo

puts "hello"
CRALL
    buf.text=(rubycode)
    
    assert_equal 2, smp.root.children.length
    
    buf.insert(buf.line_start(4), "HI")
    assert_equal 3, smp.root.children.length
    assert_equal "string.unquoted.heredoc.ruby", smp.root.children[1].name
  end
  
  def test_insert_text_in_line_repeated
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    initcode = "# Comment line one\n# Comment line two\n"
    buf.text=(initcode)
    
    assert_equal 2, smp.root.children.length
    
    %w{F i l e}.each do |l|
      buf.insert(buf.line_end1(2), l)
    end
    
    assert_equal 3, smp.root.children.length
    new_scope = smp.root.children[2]
    assert_equal([0, 4, "variable.other.constant.ruby"],
                 [new_scope.start.offset,
                  new_scope.end.offset,
                  new_scope.name])
    
    buf.insert(buf.line_end1(2), ".")
    assert_equal 4, smp.root.children.length
    new_scope = smp.root.children[2]
    assert_equal([0, 4, "variable.other.constant.ruby"],
                 [new_scope.start.offset,
                  new_scope.end.offset,
                  new_scope.name])
  end
  
  def test_insert_text_in_line_repeated2
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    "puts \"hello ".split(//).each do |l|
      buf.insert(buf.line_end1(0), l)
    end
    assert_equal 1, smp.root.children.length
    assert_equal 1, smp.root.children[0].children.length
    str_scope = smp.root.children[0]
    assert_equal "string.quoted.double.ruby", str_scope.name
    assert_equal 5, str_scope.start.offset
    "\#{1+2".split(//).each do |l|
      buf.insert(buf.line_end1(0), l)
    end
    emb_scope = str_scope.children[1]
    assert_equal 4, emb_scope.children.length
    "}\"".split(//).each do |l|
      buf.insert(buf.line_end1(0), l)
    end
    emb_scope = str_scope.children[1]
    assert_equal 5, emb_scope.children.length
    assert_equal 3, str_scope.children.length
  end
  
  def test_insert_in_line_bug_with_comments
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    initcode = "# Comment line one"
    buf.text=(initcode)
    %w(R e).each_with_index do |l, i|
      buf.insert(buf.iter(TextLoc(0, i)), l)
    end
    assert_equal 2, smp.root.children.length
  end
  
  def test_delete_text_from_line
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    buf.text=(rubycode)
    
    old = smp.root.pretty2
    
    # no changes to scopes:
    buf.delete(buf.line_start(2), buf.iter(buf.line_start(2).offset+2))
    assert_equal old, smp.root.pretty2
  end
  
  def test_delete_text_that_opens_scope_from_line
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode=<<CROW
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
CROW
    buf.text=(rubycode)
    
    assert_equal 3, smp.root.children.length
    off = buf.line_start(1).offset+2
    buf.delete(buf.iter(off), buf.iter(off+2))
    assert_equal 9, smp.root.children.length
  end
  
  def test_delete_text_that_closes_scope_from_line
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode=<<CROW
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
CROW
    buf.text=(rubycode)
    
    assert_equal 3, smp.root.children.length
    off = buf.line_start(4).offset
    buf.delete(buf.iter(off), buf.iter(off+2))
    assert_equal 2, smp.root.children.length
  end
  
  def test_delete_return_from_line
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    buf.text=(rubycode)
    
    buf.delete(buf.line_end1(1), buf.line_end(1))
    assert_equal 4, smp.root.children.length
  end
  
  def test_delete_line 
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    buf.text=(rubycode)
    
    buf.delete(buf.line_start(2), buf.line_end(2))
    assert_equal 5, buf.line_count
    assert_equal 4, smp.root.children.length
  end
  
  def test_delete_line_that_opens_scope
    source=<<POOF
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
POOF
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=(source)
    
    assert_equal 3, smp.root.children.length
    buf.delete(buf.line_start(1), buf.line_end(1))
    assert_equal 7, smp.root.children.length
  end
  
  def test_delete_line_that_closes_scope
    source=<<ENDSTR
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
ENDSTR
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=(source)
    
    assert_equal 3, smp.root.children.length
    buf.delete(buf.line_start(4), buf.line_end(4))
    assert_equal 2, smp.root.children.length
    assert_equal [0, 1], smp.root.children.map{|c|c.start.line}
  end
  
  def test_insert_line
    source=<<LOKI
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
LOKI
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=(source)

    assert_equal 3, smp.root.children.length
    buf.insert(buf.line_start(1), "@foobar\n")
    assert_equal 4, smp.root.children.length
    buf.insert(buf.line_start(6), "puts \"woot\"\n")
    assert_equal 5, smp.root.children.length
  end
  
  def test_parsing_inserted_line_that_opens_new_scope
    source=<<LOKI
puts "hello"
  Here.foo
  Here.foo
puts "hello"
LOKI
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=(source)
    
    assert_equal 6, smp.root.children.length
    buf.insert(buf.line_start(1), "foo=\<\<HI\n")
    assert_equal 2, smp.root.children.length
  end
  
  def test_parsing_inserted_line_that_closes_scope
    source=<<LOKI
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
puts "hello"
LOKI
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=(source)
    
    assert_equal 2, smp.root.children.length
    buf.insert(buf.line_end(3), "HI\n")
    assert_equal 3, smp.root.children.length
  end
  
  def test_insert
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    buf.text=(source)
    
    assert_equal 11, smp.root.children.length
    
    buf.insert(buf.iter(TextLoc(3, 14)), "\nclass Red; attr :foo; end\nFile.rm")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup
class Red; attr :foo; end
File.rm(:output => :silent)
Gtk.main
STR
    assert_equal newsource, buf.text
    assert_equal 19, smp.root.children.length
  end

  def test_insert_new_lines
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    buf.text=(source)
    assert_equal 11, smp.root.children.length
    
    buf.insert(buf.line_start(3), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'

Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal newsource, buf.text
    assert_equal 11, smp.root.children.length
    
    buf.insert(buf.iter(TextLoc(3, 0)), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'


Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal 11, smp.root.children.length
    
    buf.insert(buf.iter(TextLoc(3, 0)), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'



Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal 11, smp.root.children.length
  end
  
  def test_delete_between
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    buf.text=(source)
    puts smp.root.pretty2
    buf.delete(buf.iter(TextLoc(0, 7)), buf.iter(TextLoc(3, 9)))
    
    new_source=<<BSTR
#! /usrartup(:output => :silent)
Gtk.main
BSTR
    assert_equal new_source, buf.text
    puts smp.root.pretty2
    assert_equal 3, smp.root.children.length
  end
  

  def test_bug
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    buf.text=(source)
    
    arr = %w{p u t s} << " " << "\"" << "h" << "#" << "{"
    arr.each_with_index do |l, i|
      buf.insert(buf.iter(TextLoc(1, i)), l)
    end
#     iter = buf.iter(buf.line_end1(1).offset-1)
#     buf.delete(iter, buf.line_end1(1))
#     iter = buf.iter(buf.line_end1(1).offset-1)
#     buf.delete(iter, buf.line_end1(1))
#     iter = buf.iter(buf.line_end1(1).offset-1)
#     buf.delete(iter, buf.line_end1(1))
#     buf.insert(buf.line_end(1), "\"")
#     assert_equal 2, smp.root.children[1].children.length
  end

  def test_embedded_grammar
    gr = @ruby_grammar
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
#! /usr/bin/env ruby
foo<<-HTML
<p>Foo</p>
HTML
STR
    buf.text=(source)
    
    assert_equal "string.unquoted.embedded.html.ruby", smp.root.children[1].name
    assert_equal "meta.tag.block.any.html", smp.root.children[1].children[1].name
  end
  
  def test_embedded_grammar2
    gr = Redcar::EditView::Grammar.grammar :name => 'Ruby'
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
    html_template=<<-HTML
  <title><%= :foo %></title>
HTML
STR
    buf.text=(source)
    
    assert_equal("constant.other.symbol.ruby",
                 smp.root.children[1].children[2].children[1].name)
  end
  
  def test_embedded_grammar_delete_closing_scope
    gr = Redcar::EditView::Grammar.grammar :name => 'Ruby'
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
    html_template=<<-HTML
  <title><%= :foo %></title>
HTML
File
STR
    buf.text=(source)
    
    assert_equal 3, smp.root.children.length
    assert_equal "variable.other.constant.ruby", smp.root.children.last.name
    buf.delete(buf.iter(TextLoc(2, 2)), buf.iter(TextLoc(2, 4)))
    
    assert_equal 2, smp.root.children.length
  end
  
  def test_duplicate_nonclosing_bug
    gr = Redcar::EditView::Grammar.grammar :name => 'Ruby'
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    buf.text=("")
    
    arr = [] << "p" << " " << "\"" << "a" << "\""
    arr.each_with_index do |l, i|
      buf.insert(buf.iter(buf.char_count), l)
    end
    assert_equal 1, smp.root.children.length
    buf.insert(buf.iter(buf.char_count), "\n")
    assert_equal 1, smp.root.children.length
  end
  
  def test_incremental_the_same_as_all_at_once
    gr = Redcar::EditView::Grammar.grammar :name => 'Ruby'
    buf, smp = ParserTests.clean_parser_and_buffer(gr)
    source=<<STR
foo=<<H
STR
    source[0..-2].split(//).each do |l|
      buf.insert(buf.iter(buf.char_count), l)
    end
    
    gr1 = Redcar::EditView::Grammar.grammar :name => 'Ruby'
    buf1, smp1 = ParserTests.clean_parser_and_buffer(gr1)
    buf1.text=(source[0..-2])
    
    assert_equal smp.root.pretty2, smp1.root.pretty2
  end
  
  end
end
