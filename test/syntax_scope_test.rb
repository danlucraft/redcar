
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

xml = IO.readlines(File.dirname(__FILE__)+"/../textmate/bundles/Ruby.tmbundle/Syntaxes/Ruby.plist").join
plist = Redcar::Plist.xml_to_plist(xml)
$ruby_grammar = Redcar::Syntax::Grammar.new(plist[0])

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
    
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)    
    @scope_tree = smp.scope_tree
    
    $debug_puts = false
  end
  
  def teardown
  end
  
  def test_scope
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    assert sm
  end
  
  def test_scope_adds_child
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    
    sm2 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 0),
                    :end => TextLoc.new(1, 0))
    sm.add_child(sm2)
    assert_equal 1, sm.children.length
    assert_equal sm, sm.children[0].parent
  end
  
#   def test_scope_checks_children_do_not_overlap
#     gr = Grammar.new(@grammar1)
#     sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
#                    :grammar => gr,
#                    :start => TextLoc.new(0, 0))
    
#     sm2 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
#                     :grammar => gr,
#                     :start => TextLoc.new(0, 1),
#                     :end => TextLoc.new(1, 0))
#     sm3 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
#                     :grammar => gr,
#                     :start => TextLoc.new(0, 2),
#                     :end => TextLoc.new(2, 0))
#     sm.add_child(sm2)
#     assert_raises(OverlappingScopeException) do
#       sm.add_child(sm3)
#     end
#   end
  
  def test_scope_checks_children_do_not_overlap_when_not_complete_scopes
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    
    sm2 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 1),
                    :end => nil)
    sm3 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 2),
                    :end => TextLoc.new(2, 0))
    sm.add_child(sm2)
    assert sm.add_child(sm3)
  end

  def test_scope_at_location
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    sm2 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 3),
                    :end => TextLoc.new(0, 5))
    sm3 = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(1, 2),
                    :end => TextLoc.new(2, 0))
    sm.add_child(sm2)
    sm2.parent = sm
    sm.add_child(sm3)
    sm3.parent = sm
    assert_equal sm, sm.scope_at(TextLoc.new(0, 0))
    assert_equal sm, sm.scope_at(TextLoc.new(0, 1))
    assert_equal sm2, sm.scope_at(TextLoc.new(0, 4))
    assert_equal sm3, sm.scope_at(TextLoc.new(1, 8))
    
  end

  def test_scope_line_start_and_end
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    sm1 = Scope.new(:pattern => gr.pattern("string.quoted.double.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 0),
                    :end => TextLoc.new(0, 2))
    sm2 = Scope.new(:pattern => gr.pattern("string.quoted.double.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(0, 3),
                    :end => TextLoc.new(0, 5))
    sm3 = Scope.new(:pattern => gr.pattern("string.quoted.double.untitled"),
                    :grammar => gr,
                    :start => TextLoc.new(1, 2),
                    :end => TextLoc.new(2, 5))
    sm.add_child(sm2)
    sm.add_child(sm3)
    assert_equal sm, sm.line_start(0)
    assert_equal sm, sm.line_end(0)
    assert_equal sm, sm.line_start(1)
    assert_equal sm3, sm.line_end(1)
    assert_equal sm3, sm.line_start(2)
    assert_equal sm, sm.line_end(2)
    
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    st = smp.scope_tree
    assert_equal "keyword.control.class.ruby", st.scope_at(TextLoc.new(0, 0)).name
    assert_equal "source.ruby", st.line_start(0).name
  end
  
  def test_scope_line_start_and_end_with_nothing_there
    gr = Grammar.new(@grammar1)
    sm = Scope.new(:pattern => gr.pattern("keyword.control.untitled"),
                   :grammar => gr,
                   :start => TextLoc.new(0, 0))
    assert_equal sm, sm.scope_at(TextLoc.new(0, 0))
  end
  
  def test_adds_child_in_the_right_place
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)
    names = smp.scope_tree.children.map{|c| c.name}
    sc2 = Scope.new(:pattern => gr.pattern("entity.name.type.class.ruby"),
                    :grammar => gr,
                    :name    => "entity.name.type.class.ruby",
                    :start   => TextLoc.new(0, 21),
                    :end     => TextLoc.new(0, 26))
    smp.scope_tree.add_child(sc2)
    assert_equal(names.insert(1, "entity.name.type.class.ruby"), 
                 smp.scope_tree.children.map{|c| c.name})
  end
  
  def test_clear_between
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)    
    names = smp.scope_tree.children.map{|c| c.name}
    smp.clear_between(1, 2)
    assert_equal([names[0]]+names[4..5], 
                 smp.scope_tree.children.map{|c| c.name})
  end
    
  def test_clear_line
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)    
    names = smp.scope_tree.children.map{|c| c.name}
    smp.clear_line(1)
    assert_equal([names[0]]+names[2..5], 
                 smp.scope_tree.children.map{|c| c.name})
  end
  
  def test_scope_hierarchy
    gr = $ruby_grammar
    sc = Scope.new(:pattern => gr,
                   :grammar => gr,
                   :start   => TextLoc.new(0, 0))
    smp = Parser.new(sc, [gr], nil)
    rubycode = "class Redcar::File\n  def nice_name\n    @filename.split(\"/\").last\n  end\nend\n"
    smp.add_lines(rubycode)    
    assert_equal(["source.ruby", "meta.class.ruby", "keyword.control.class.ruby"],
                 smp.scope_tree.children[0].children[0].hierarchy_names)
  end
  
  def test_common_ancestor
    st = @scope_tree
    can1 = Scope.common_ancestor(st.children[0].children[0], st.children[0].children[1])
    assert_equal st.children[0], can1
    can2 = Scope.common_ancestor(st.children[0].children[0], st.children[3].children[1])
    assert_equal st, can2
  end
  
  def test_copy
    copy = @scope_tree.copy
    pre_num = @scope_tree.children.length
    assert_equal copy.children.length, pre_num
    copy.children.clear
    assert_equal pre_num, @scope_tree.children.length
  end
  
  def test_clear_not_on_line
    @scope_tree.clear_not_on_line(2)
    assert_equal 2, @scope_tree.children.length
    assert_equal(@scope_tree.children[0].start.line,
                 @scope_tree.children[1].start.line)
  end
  
  def test_identical
    copy = @scope_tree.copy
    
    assert copy.identical?(@scope_tree)
    copy.clear_not_on_line(2)
    assert !copy.identical?(@scope_tree)
  end
  
  def test_shift_chars
    off1 = @scope_tree.children[2].start.offset
    off2 = @scope_tree.children[3].start.offset
    @scope_tree.shift_chars(2, 10, 17)
    assert_equal off1, @scope_tree.children[2].start.offset
    assert_equal off2+10, @scope_tree.children[3].start.offset
  end
  
  def test_first_child_after
    f = @scope_tree.children[0].first_child_after(TextLoc.new(0, 5))
    assert_equal f, @scope_tree.children[0].children[1]
  end
end
