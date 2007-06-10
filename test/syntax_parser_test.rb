
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

xml = IO.readlines(File.dirname(__FILE__)+"/../textmate/Bundles/Ruby.tmbundle/Syntaxes/Ruby.plist").join
plist = Redcar::Plist.xml_to_plist(xml)
$ruby_grammar = Redcar::Syntax::Grammar.new(plist[0])
xml2 = IO.readlines(File.dirname(__FILE__)+"/../textmate/Bundles/HTML.tmbundle/Syntaxes/HTML.plist").join
plist2 = Redcar::Plist.xml_to_plist(xml2)
$html_grammar = Redcar::Syntax::Grammar.new(plist2[0])
Redcar::Syntax.load_grammars

class TestSyntax < Test::Unit::TestCase
  include Redcar
  include Redcar::Syntax
  
  def setup
    @grammar1 =
      { "name" => "My Language",
      "comment" => "Example grammar 1",
      "scopeName" => 'source.untitled',
      "fileTypes" => [ ".rb", ".rjs" ],
      "firstLineMatch" => "#! /usr/bin/ruby",
      "foldingStartMarker" => '\{\s*$',
      "foldingStopMarker" => '^\s*\}',
      "patterns" => [
                     {  "name" => 'keyword.control.untitled',
                       "match" => '\b(if|while|for|return)\b'
                     },
                     {  "name" => 'string.quoted.double.untitled',
                       "begin" => '"',
                       "end" => '"',
                       "patterns" => [
                                      {  "name" => 'constant.character.escape.untitled',
                                        "match" => '\\.',
                                      }
                                     ]
                     }
                    ]
    }
    
    @grammar2 = { 
      "scopeName" => "source.example",
      "patterns" => [{ "name" => "keyword.control.untitled",
                       "match" => '\b(if|while|for|return)\b' }
                    ]
    }
    
    @lisp_grammar = {"name"=>"Lisp",
      "fileTypes"=>["lisp", "cl", "l", "mud", "el"],
      "scopeName"=>"source.lisp",
      "uuid"=>"00D451C9-6B1D-11D9-8DFA-000D93589AF6",
      "foldingStartMarker"=>"\\(",
      "foldingStopMarker"=>"\\)",
      "keyEquivalent"=>"^~L",
      "comment"=>"Simple grammar for all Lisp variants",
      "patterns"=>
      [{"name"=>"comment.line.semicolon.lisp",
         "captures"=>{"1"=>{"name"=>"punctuation.definition.comment.lisp"}},
         "match"=>"(;).*$\\n?"},
       {"name"=>"meta.function.lisp",
         "captures"=>
         {"2"=>{"name"=>"storage.type.function-type.lisp"},
           "4"=>{"name"=>"entity.name.function.lisp"}},
         "match"=>
         "(\\b(?i:(defun|defmethod|defmacro))\\b)(\\s+)((\\w|\\-|\\!|\\?)*)"},
       {"name"=>"constant.character.lisp",
         "captures"=>{"1"=>{"name"=>"punctuation.definition.constant.lisp"}},
         "match"=>"(#)(\\w|[\\\\+-=<>'\"&#])+"},
       {"name"=>"variable.other.global.lisp",
         "captures"=>
         {"1"=>{"name"=>"punctuation.definition.variable.lisp"},
           "3"=>{"name"=>"punctuation.definition.variable.lisp"}},
         "match"=>"(\\*)(\\S*)(\\*)"},
       {"name"=>"keyword.control.lisp",
         "match"=>"\\b(?i:case|do|let|loop|if|else|when)\\b"},
       {"name"=>"keyword.operator.lisp", "match"=>"\\b(?i:eq|neq|and|or)\\b"},
       {"name"=>"constant.language.lisp", "match"=>"\\b(?i:null|nil)\\b"},
       {"name"=>"support.function.lisp",
         "match"=>
      "\\b(?i:cons|car|cdr|cond|lambda|format|setq|setf|quote|eval|append|list|listp|memberp|t|load|progn)\\b"},
       {"name"=>"constant.numeric.lisp",
         "match"=>
      "\\b((0(x|X)[0-9a-fA-F]*)|(([0-9]+\\.?[0-9]*)|(\\.[0-9]+))((e|E)(\\+|-)?[0-9]+)?)(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\\b"},
       {"name"=>"string.quoted.double.lisp",
         "endCaptures"=>{"0"=>{"name"=>"punctuation.definition.string.end.lisp"}},
         "begin"=>"\"",
         "beginCaptures"=>
         {"0"=>{"name"=>"punctuation.definition.string.begin.lisp"}},
         "end"=>"\"",
         "patterns"=>
         [{"name"=>"constant.character.escape.lisp", "match"=>"\\\\."}]}]
    }
    
    $debug_puts = false
  end
  
  def teardown
  end

 def test_parser
    gr = Grammar.new(@grammar1)
    sc = Scope.new(:grammar => gr,
                   :pattern => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], "")
    assert smp
    assert_equal "source.untitled", smp.scope_tree.name
  end
  
  def test_parse_line_with_matches
    line = "asdf asdf if asdf asdf for asdfa asdf"
    grh = { 
      "name" => "Grammar Test",
      "scopeName" => "source.example1",
      "patterns" => [ {"name" => "if", "match" => "\\b(if|for)\\b"} ] }
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(line)
    run_gtk
    assert_equal "source.example1", smp.scope_tree.name
    assert_equal 2, smp.scope_tree.children.length
    smp.scope_tree.children.each do |cs|
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
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(line)
    run_gtk
    assert_equal "source.example1", smp.scope_tree.name
    assert_equal 3, smp.scope_tree.children.length
    assert_equal "if", smp.scope_tree.children[0].name
    assert_equal "if", smp.scope_tree.children[2].name
    assert_equal "string", smp.scope_tree.children[1].name
    assert_equal 1, smp.scope_tree.children[1].children.length
    assert_equal "constant.character.escape.untitled", smp.scope_tree.children[1].children[0].name
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
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(line)
    run_gtk
    assert_equal "source.example1", smp.scope_tree.name
    assert_equal 1, smp.scope_tree.children.length
    ch0 = smp.scope_tree.children[0]
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
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(line)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    assert_equal "keyword.if", smp.scope_tree.children[0].name
    assert_equal 3, smp.scope_tree.children[1].children.length
    assert_equal "keyword.if", smp.scope_tree.children[1].children[0].name
    assert_equal "code.collection.set", smp.scope_tree.children[1].children[1].name
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
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(line)
    run_gtk
    assert_equal 1, smp.scope_tree.children.length
    assert_equal 1, smp.scope_tree.children[0].children.length
    assert_equal "code.list", smp.scope_tree.children[0].name
    assert_equal "code.list", smp.scope_tree.children[0].children[0].name
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
    gr = Grammar.new(grh)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(lines)
    run_gtk
    assert_equal 1, smp.scope_tree.children.length
    assert_equal 1, smp.scope_tree.children[0].children.length
  end
  
  def test_parse_text_bug
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    text = File.read("test/fixtures/init.rb")
    smp.add_lines(text)
    run_gtk
  end
  
  def test_parse_text_bug_for_included_base_pattern
    gr = $ruby_grammar
    sc = Scope.new( :pattern => gr,
                    :grammar => gr,
                    :start => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<HI
require "foobar"
HI
    smp.add_lines(source, :lazy => false)
    assert_equal 2, smp.scope_tree.children[0].children.length
  end
  
  # Parse line should work repeatedly with no ill effects.
  def test_re_parse_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"asdf \#{foo} asdf\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    copy = smp.scope_tree.copy
    10.times { assert smp.parse_line("class Redcar::File\n", 0) }
    assert copy.identical?(smp.scope_tree)
  end
  
  # ... even when there are opening scopes in the line
  def test_re_parse_line_with_opening_scopes
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<P1END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P1END
    smp.add_lines(rubycode)
    run_gtk
    copy = smp.scope_tree.copy
    1.times { assert smp.parse_line("foo=\<\<HI", 1) }
    assert copy.identical?(smp.scope_tree)
  end
  
  # ... or closing scopes.
  def test_re_parse_line_with_closing_scopes
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<P2END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P2END
    smp.add_lines(rubycode)
    run_gtk
    copy = smp.scope_tree.copy
    10.times { assert smp.parse_line("HI", 4) }
    assert copy.identical?(smp.scope_tree)
  end
  
  # Reparsing should also work ok when there are new things. 
  
  # Like new single scopes ...
  def test_re_parse_line_with_extra_single_scopes
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<P2END
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
P2END
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    assert smp.parse_line("puts \"hello\", @hello", 0)
    assert_equal 4, smp.scope_tree.children.length
  end
  
  # ... and new opening scopes. Here parse_line should return 
  # false to indicate the scope at the end of the line has changed ...
  def test_re_parse_line_with_extra_opening_scopes
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"asdf asdf\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
    assert !smp.parse_line("    @filename.split(\"asdf asdf\").last=\<\<HI", 2)
    assert_equal 7, smp.scope_tree.children.length # <- this is not up to date for the entire text.
  end
  
  # ... and the same for new closing scopes. 
  def test_re_parse_line_with_extra_closing_scopes
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<APE
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo

puts "hello"
APE
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 2, smp.scope_tree.children.length
    assert_equal "string.unquoted.heredoc.ruby", smp.scope_tree.line_end(4).name
    assert !smp.parse_line("HI", 4)
    assert_equal 2, smp.scope_tree.children.length # <- this is not up to date for the entire text.
    assert_equal "source.ruby", smp.scope_tree.line_end(4).name
  end
  
  def test_shift_after
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal [0, 1, 2, 2, 3, 4], smp.scope_tree.children.map{|c| c.start.line}
    smp.shift_after(2, 2)
    assert_equal [0, 1, 4, 4, 5, 6], smp.scope_tree.children.map{|c| c.start.line}
  end
  
  def test_captures_are_children_for_single_scope
    source=<<ENDSTR;
; Here is a comment
(defun hello (x y)
  (+ x y))
ENDSTR
    gr = Grammar.new(@lisp_grammar)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source, :lazy => false)
    assert_equal "comment.line.semicolon.lisp", smp.scope_tree.children[0].name
    assert_equal 1, smp.scope_tree.children[0].children.length
    assert_equal "punctuation.definition.comment.lisp", smp.scope_tree.children[0].children[0].name
    
  end
  
  def test_captures_are_children_for_double_scope
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "puts \"\#{1+2}\""
    smp.add_lines(rubycode, :lazy => false)
    
    assert_equal 1, smp.scope_tree.children.length
    assert_equal "source.ruby.embedded.source", smp.scope_tree.children[0].
      children[1].pattern.name
    assert_equal(["punctuation.section.embedded.ruby",
                  "constant.numeric.ruby",
                  "constant.numeric.ruby",
                  "punctuation.section.embedded.ruby"],
                 smp.scope_tree.children[0].children[1].children.map{|c| c.name})
  end
  
  def test_begin_and_end_captures_are_children_for_double_scope
    source=<<ENDSTR;
; Here is a comment
(defun hello (x y)
  (+ x y))
(hello "foo" "bar")
ENDSTR
    gr = Grammar.new(@lisp_grammar)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)
    run_gtk

    assert_equal "string.quoted.double.lisp", smp.scope_tree.children[2].name
    assert_equal "string.quoted.double.lisp", smp.scope_tree.children[3].name
    assert_equal 2, smp.scope_tree.children[2].children.length
    assert_equal 2, smp.scope_tree.children[3].children.length
    assert_equal "punctuation.definition.string.begin.lisp", smp.scope_tree.children[2].children[0].name
    assert_equal "punctuation.definition.string.end.lisp", smp.scope_tree.children[2].children[1].name
    assert_equal(smp.scope_tree.children[2].children[1].end, 
                 smp.scope_tree.children[2].end)
  end
  
  def test_lisp_grammar
    source=<<ENDSTR;
(car (1 2 3))
ENDSTR
    gr = Grammar.new(@lisp_grammar)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)

    assert_equal 4, smp.scope_tree.children.length
    assert_equal "support.function.lisp", smp.scope_tree.children[0].name
    assert_equal "constant.numeric.lisp", smp.scope_tree.children[1].name
  end  
  
#   def test_folds
#     source="{\n  hello { }\n}\n{\n  {\n    foobar\n  }\n}\n"
# #    0 1
# #    1 0
# #    0 -1
# #    0 1
# #    1 1
# #    2 0
# #    1 -1
# #    0 -1
    
#     gr = Grammar.new(@grammar1)
#     sc = Scope.new(:pattern => gr,
#                    :grammar => gr,
#                    :start   => TextLoc.new(0, 0))
#     smp = Parser.new(sc, [gr], nil)
#     smp.add_lines(source)
#     assert_equal 1, smp.fold_counts[0]
#     assert_equal 0, smp.fold_counts[1]
#     assert_equal -1, smp.fold_counts[2]
#     assert_equal 1, smp.fold_counts[3]
#     assert_equal 1, smp.fold_counts[4]
#     assert_equal 0, smp.fold_counts[5]
#     assert_equal -1, smp.fold_counts[6]
#     assert_equal -1, smp.fold_counts[7]

#     [0, 1, 0, 0, 1, 2, 1, 0].each_with_index do |ind, i|
#       assert_equal ind, smp.indent(i), "indent #{ind} expected at line #{i}"
#     end
#   end
  
  def test_ruby_syntax
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)

    rubycode = "class Foo\n  def hello\n    puts \"hello\"\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    
    assert_equal 5, smp.scope_tree.children.length
    class_scope = smp.scope_tree.children[0]
    assert_equal "meta.class.ruby", class_scope.name
    
    # let's assert that zero length scopes don't exist in the scope tree.
    assert_equal 2, class_scope.children.length
    
    # def is in the right place?
    method_def_scope = smp.scope_tree.children[1].children[0]
    assert_equal 2, method_def_scope.start.offset
    assert_equal 5, method_def_scope.end.offset
  end
  
  def test_ruby_syntax2
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<ENDSTR
class Redcar::File
  def nice_name
    @filename.split("/").last
  end
end
ENDSTR
    smp.add_lines(rubycode)
    run_gtk

    # check that the "class" and "Redcar::File" are picked up:
    class_scope = smp.scope_tree.children[0]
    assert_equal 0, class_scope.children[0].start.offset
    assert_equal 5, class_scope.children[0].end.offset
    assert_equal 6, class_scope.children[1].start.offset
    assert_equal 18, class_scope.children[1].end.offset
  end

  def test_ruby_interpolated_ruby
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "puts \"asdf \#{1+2} asdf\""
    smp.add_lines(rubycode)
    run_gtk
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
      
    gr = Grammar.new(hash)
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    md = gr.pattern("text.heredoc").begin.match("text=\<\<END:FOR")
    smp = Parser.new(sc, [gr], nil)
    assert_equal "^END,FOR$", smp.build_closing_regexp(gr.pattern("text.heredoc"), md)
  end

  def test_clear_after
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    smp.clear_after(2)
    assert_equal 2, smp.scope_tree.children.length
  end
  
  def test_insert_text_in_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
    
    old = smp.scope_tree.copy
    old.shift_chars(2, 4, 0)
    
    # no changes to scopes:
    smp.insert_in_line(2, "    ", 0)
    run_gtk
    assert smp.scope_tree.identical?(old)
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
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    assert smp.scope_tree.children[1].end # heredoc is closed
    copy = smp.scope_tree.copy
    copy.shift_chars(1, 2, 0)
    
    smp.insert_in_line(1, "a;", 0)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    assert smp.scope_tree.children[1].end # heredoc is closed
    assert copy.identical?(smp.scope_tree)
  end
  
  def test_insert_text_in_line_that_appends_a_scope
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
    
    smp.insert_in_line(2, "(\"asdf\")", smp.text[2].length)
    assert_equal 7, smp.scope_tree.children.length
  end
  
  def test_insert_text_in_line_that_prepends_a_scope
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
    
    smp.insert_in_line(2, "@thing ", 4)
    assert_equal 7, smp.scope_tree.children.length
  end
  
  def test_insert_text_in_line_that_adds_an_opening_scope
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
    
    smp.insert_in_line(2, "=\<\<HI", smp.text[2].length)
    run_gtk
    assert_equal 5, smp.scope_tree.children.length
    assert_equal "string.unquoted.heredoc.ruby", smp.scope_tree.children.last.name
  end
  
  def test_insert_text_in_line_that_adds_a_closing_scope
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<CRALL
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo

puts "hello"
CRALL
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 2, smp.scope_tree.children.length
    
    smp.insert_in_line(4, "HI", 0)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
  end
  
  def test_insert_text_in_line_repeated
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    initcode = "# Comment line one\n# Comment line two\n"
    smp.add_lines(initcode)
    run_gtk
    assert_equal 2, smp.scope_tree.children.length
    
    %w{F i l e}.each do |l|
      smp.insert_in_line(2, l, smp.text[2].length)
    end
    assert_equal 3, smp.scope_tree.children.length
    new_scope = smp.scope_tree.children[2]
    assert_equal([0, 4, "variable.other.constant.ruby"],
                 [new_scope.start.offset,
                  new_scope.end.offset,
                  new_scope.name])
    
    smp.insert_in_line(2, ".", smp.text[2].length)
    assert_equal 3, smp.scope_tree.children.length
    new_scope = smp.scope_tree.children[2]
    assert_equal([0, 4, "variable.other.constant.ruby"],
                 [new_scope.start.offset,
                  new_scope.end.offset,
                  new_scope.name])
  end
  
  def test_insert_text_in_line_repeated2
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], "#asdf\n")
    "puts \"hello ".split(//).each do |l|
      smp.insert_in_line(1, l, smp.text[1].length)
    end
    assert_equal 2, smp.scope_tree.children.length
    str_scope = smp.scope_tree.children[1]
    assert_equal "string.quoted.double.ruby", str_scope.name
    assert_equal 5, str_scope.start.offset
    "\#{1+2".split(//).each do |l|
      smp.insert_in_line(1, l, smp.text[1].length)
    end
    emb_scope = str_scope.children[1]
    assert_equal 3, emb_scope.children.length
    "}\"".split(//).each do |l|
      smp.insert_in_line(1, l, smp.text[1].length)
    end
    emb_scope = str_scope.children[1]
    assert_equal 4, emb_scope.children.length
    assert_equal 3, str_scope.children.length
  end
  
  def test_insert_in_line_bug_with_comments
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    initcode = "# Comment line one"
    smp.add_lines(initcode, :lazy => false)
    %w(R e).each_with_index do |l, i|
      smp.insert(TextLoc.new(0, i), l)
      run_gtk
    end
    assert_equal 2, smp.scope_tree.children.length
  end
  
  def test_delete_text_from_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode="class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    
    old = smp.scope_tree.copy
    old.shift_chars(2, -2, 0)
    
    # no changes to scopes:
    smp.delete_from_line(2, 2, 0)
    assert smp.scope_tree.identical?(old)
  end
  
  def test_delete_text_that_opens_scope_from_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<CROW
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
CROW
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    smp.delete_from_line(1, 2, 4)
    run_gtk
    assert_equal 6, smp.scope_tree.children.length
  end
  
  
  def test_delete_text_that_closes_scope_from_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode=<<CROW
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
HI
puts "hello"
CROW
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 3, smp.scope_tree.children.length
    smp.delete_from_line(4, 2, 0)
    assert_equal 2, smp.scope_tree.children.length
  end
  
  def test_delete_return_from_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    run_gtk
    assert_equal 6, smp.text.length
    smp.delete_between(TextLoc.new(1, 15), TextLoc.new(2,0))
    assert_equal 5, smp.text.length
  end
  
#   def test_delete_line 
#     gr = $ruby_grammar
#      sc = Scope.new(:pattern => gr,
#                     :grammar => gr,
#                     :start   => TextLoc.new(0, 0))
#      smp = Parser.new(sc, [gr], nil)
#      rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
#      smp.add_lines(rubycode)
#     run_gtk
#      smp.delete_line(2)
#      assert_equal 4, smp.scope_tree.children.length
#      assert_equal 2, smp.scope_tree.children[2].start.line
#   end
  
#   def test_delete_line_that_opens_scope
#     source=<<POOF
# puts "hello"
# foo=\<\<HI
#   Here.foo
#   Here.foo
# HI
# puts "hello"
# POOF
#     gr = $ruby_grammar
#     sc = Scope.new(:pattern => gr,
#                    :grammar => gr,
#                    :start   => TextLoc.new(0, 0))
#     smp = Parser.new(sc, [gr], nil)
#     smp.add_lines(source)
#     run_gtk
#     assert_equal 3, smp.scope_tree.children.length
#     smp.delete_line(1)
#     assert_equal 5, smp.scope_tree.children.length
#   end
  
#   def test_delete_line_that_closes_scope
#     source=<<ENDSTR
# puts "hello"
# foo=<<HI
#   Here.foo
#   Here.foo
# HI
# puts "hello"
# ENDSTR
#     gr = $ruby_grammar
#     sc = Scope.new(:pattern => gr,
#                    :grammar => gr,
#                    :start   => TextLoc.new(0, 0))
#     smp = Parser.new(sc, [gr], nil)
#     smp.add_lines(source)
#     run_gtk
#     assert_equal 3, smp.scope_tree.children.length
#     smp.delete_line(4)
#     assert_equal 2, smp.scope_tree.children.length
#     assert_equal [0, 1], smp.scope_tree.children.map{|c|c.start.line}
#   end
  
  def test_insert_line
    source=<<LOKI
puts "hello"
foo=<<HI
  Here.foo
  Here.foo
HI
puts "hello"
LOKI
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)
    run_gtk

    assert_equal 3, smp.scope_tree.children.length

    smp.insert_line("@foobar", 1)
    run_gtk
    assert_equal 4, smp.scope_tree.children.length

    smp.insert_line("puts \"woot\"", 6)
    run_gtk
    assert_equal 5, smp.scope_tree.children.length
  end
  
  def test_parsing_inserted_line_that_opens_new_scope
    source=<<LOKI
puts "hello"
  Here.foo
  Here.foo
puts "hello"
LOKI
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)
    run_gtk
    assert_equal 4, smp.scope_tree.children.length
    
    smp.insert_line("foo=\<\<HI", 1)
    run_gtk
    assert_equal 2, smp.scope_tree.children.length
  end
  
  def test_parsing_inserted_line_that_closes_scope
    source=<<LOKI
puts "hello"
foo=\<\<HI
  Here.foo
  Here.foo
puts "hello"
LOKI
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    smp.add_lines(source)
    run_gtk
    assert_equal 2, smp.scope_tree.children.length
    
    smp.insert_line("HI", 4)
    assert_equal 3, smp.scope_tree.children.length
  end
  
  def test_insert
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    smp.add_lines(source)
    run_gtk
    assert_equal 6, smp.text.length
    assert_equal 6, smp.scope_tree.children.length
    
    smp.insert(TextLoc.new(3, 14), "\nclass Red; attr :foo; end\nFile.rm")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup
class Red; attr :foo; end
File.rm(:output => :silent)
Gtk.main
STR
    assert_equal newsource, smp.text.join
    assert_equal 8, smp.text.length
    assert_equal 11, smp.scope_tree.children.length
  end

  def test_insert_new_lines
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    smp.add_lines(source)
    run_gtk
    assert_equal 6, smp.text.length
    assert_equal 6, smp.scope_tree.children.length
    pre = smp.scope_tree.copy
    pre.shift_after(3, 1)
    
    smp.insert(TextLoc.new(3, 0), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'

Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal newsource, smp.text.join
    assert_equal 7, smp.text.length
    assert_equal 6, smp.scope_tree.children.length
    
    pre.shift_after(4, 1)
    smp.insert(TextLoc.new(3, 0), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'


Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal newsource, smp.text.join
    assert_equal 8, smp.text.length
    assert_equal 6, smp.scope_tree.children.length
    
    pre.shift_after(5, 1)
    smp.insert(TextLoc.new(3, 0), "\n")
    newsource=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'



Redcar.startup(:output => :silent)
Gtk.main
STR
    assert_equal newsource, smp.text.join
    assert_equal 9, smp.text.length
    assert_equal 6, smp.scope_tree.children.length
    assert smp.scope_tree.identical?(pre)
  end
  
  def test_insert_single_newline_at_end
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    smp.add_lines(source[0..-2])
    run_gtk
    smp.insert(TextLoc.new(4, 8), "\n")
    assert_equal "Gtk.main\n", smp.text[-2]
  end
  
  def test_delete_between
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    smp.add_lines(source)
    run_gtk
    assert_equal 6, smp.text.length
    smp.delete_between(TextLoc.new(0, 7), TextLoc.new(3, 9))
    run_gtk
    new_source=<<BSTR
#! /usrartup(:output => :silent)
Gtk.main
BSTR
    assert_equal 3, smp.text.length
    assert_equal 2, smp.scope_tree.children.length
  end
  
  def test_bug
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/lib/redcar'
Redcar.startup(:output => :silent)
Gtk.main
STR
    smp.add_lines(source)
    run_gtk
    assert_equal 6, smp.text.length
    arr = %w{p u t s} << " " << "\"" << "h" << "#" << "{"
    arr.each_with_index do |l, i|
      smp.insert(TextLoc.new(1, i), l)
    end
    smp.delete_from_line(1, 1, smp.text[1].length-1)
    smp.delete_from_line(1, 1, smp.text[1].length-1)
    smp.delete_from_line(1, 1, smp.text[1].length-1)
    smp.insert(TextLoc.new(1, smp.text[1].length), "\"")
    assert_equal 2, smp.scope_tree.children[1].children.length
  end
  
  def test_embedded_grammar
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
#! /usr/bin/env ruby
foo<<-HTML
<p>Foo</p>
HTML
STR
    smp.add_lines(source)
    run_gtk
    assert_equal "string.unquoted.embedded.html.ruby", smp.scope_tree.children[1].name
    assert_equal "meta.tag.block.any.html", smp.scope_tree.children[1].children[1].name
  end
  
  def test_embedded_grammar2
    gr = Syntax.grammar :name => 'Ruby'
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
    html_template=<<-HTML
  <title><%= :foo %></title>
HTML
STR
    smp.add_lines(source, :lazy => false)
    assert_equal("constant.other.symbol.ruby",
                 smp.scope_tree.children[0].children[2].children[1].name)
  end
  
  def test_embedded_grammar_delete_closing_scope
    gr = Syntax.grammar :name => 'Ruby'
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
    html_template=<<-HTML
  <title><%= :foo %></title>
HTML
File
STR
    smp.add_lines(source, :lazy => false)
    assert_equal 2, smp.scope_tree.children.length
    assert_equal "variable.other.constant.ruby", smp.scope_tree.children.last.name
    smp.delete_between(TextLoc(2, 2), TextLoc(2, 4))
    run_gtk
    assert_equal 1, smp.scope_tree.children.length
  end
  
  def test_embedded_grammar3
    gr = Syntax.grammar :name => 'HTML'
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    source=<<STR
<script>
</script>
STR
    smp.add_lines(source, :lazy => false)
    puts smp.scope_tree.pretty
  end
end
