
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

xml = IO.readlines(File.dirname(__FILE__)+"/../textmate/Bundles/Ruby.tmbundle/Syntaxes/Ruby.plist").join
plist = Redcar::Plist.xml_to_plist(xml)
$ruby_grammar = Redcar::Syntax::Grammar.new(plist[0])
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

  def test_load_new_grammar
    assert Grammar.new(@grammar1)
    assert gr = Grammar.new(@lisp_grammar)
  end
  
  def test_load_basic_properties
    gr = Grammar.new(@grammar1)
    assert_equal "My Language", gr.name
    assert_equal "source.untitled", gr.scope_name.to_s
    assert_equal [".rb", ".rjs"], gr.file_types
    assert_equal '\{\s*$', gr.folding_start_marker
    assert_equal '^\s*\}', gr.folding_stop_marker
    assert_equal Regexp.new("#! /usr/bin/ruby"), gr.first_line_match
    assert_equal "Example grammar 1", gr.comment
  end
  
  def test_load_pattern_from_hash
    gr = $ruby_grammar
    hash = {   
      "name" => 'string.unquoted.here-doc',
      "begin" => '<<(\w+)',  # match here-doc token
      "end" => '^\1$'        # match end of here-doc
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal 'string.unquoted.here-doc', pat.name.to_s
    assert_equal Regexp.new(hash['begin']), pat.begin
    assert_equal hash['end'], pat.end
  end
  
  def test_load_pattern_from_hash_content_name
    gr = $ruby_grammar
    hash = {   
      "contentName" => 'comment.block.preprocessor',
      "begin" => '#if 0(\s.*)?$', 
      "end" => '#endif'    
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal "comment.block.preprocessor", pat.content_name.to_s
    assert_equal "", pat.name.to_s
  end
  
  def test_load_pattern_from_hash_captures
    gr = $ruby_grammar
    hash = {   
      "match" => '(@selector\()(.*?)(\))',
      "captures" => {
        1 => { "name" => 'storage.type.objc' },
        3 => { "name" => 'storage.type.objc' }
      }
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal /(@selector\()(.*?)(\))/, pat.match
    assert_equal 2, pat.captures.keys.length
    assert_equal "storage.type.objc", pat.captures[3].to_s
  end
  
  def test_load_pattern_from_hash_include
    gr = $ruby_grammar
    hash = {   
      "begin" => '<\?(php|=)?', 
      "end" => '\?>', 
      "patterns" => [
                    { "include" => "source.php" }
                   ]
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal 1, pat.patterns.length
    assert_equal :scope, pat.patterns[0].type
    assert_equal "source.php", pat.patterns[0].value.to_s
    
    hash = {
      "begin" => '\(',
      "end" => '\)',
      "patterns" => [{ "include" => "$self"}]
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal 1, pat.patterns.length
    assert_equal :self, pat.patterns[0].type
    assert_equal nil, pat.patterns[0].value
    
    hash = {
      "begin" => '\(',
      "end" => '\)',
      "patterns" => [{ "include" => "$base"}]
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal 1, pat.patterns.length
    assert_equal :base, pat.patterns[0].type
    assert_equal nil, pat.patterns[0].value
    
    hash = {
      "begin" => '"',
      "end" => '"', 
      "patterns" => [
                     { "include" => "#escaped-char" },
                     { "include" => "#variable" }
                    ]
    }
    pat = gr.pattern_from_hash(hash)
    assert_equal 2, pat.patterns.length
    assert_equal :repository, pat.patterns[0].type
    assert_equal "escaped-char", pat.patterns[0].value
    assert_equal :repository, pat.patterns[1].type
    assert_equal "variable", pat.patterns[1].value
  end
  
  def test_load_loads_patterns
    gr = Grammar.new(@grammar1)
    assert_equal 2, gr.patterns.length
    assert_equal "keyword.control.untitled", gr.patterns[0].name.to_s
    assert_equal /\b(if|while|for|return)\b/, gr.patterns[0].match
    assert_equal "string.quoted.double.untitled", gr.patterns[1].name.to_s
    assert_equal Regexp.new('"'), gr.patterns[1].begin
    assert_equal "constant.character.escape.untitled", gr.patterns[1].patterns[0].name.to_s
  end
  
  def test_load_repository
    @grammar1['repository'] = {
      "qq_string_content" => {
        "begin" => '\(',
        "end" => '\)',
        "patterns" => [{ "include" => '#qq_string_content' }]
      }}
    gr = Grammar.new(@grammar1)
    assert_equal 1, gr.repository.length
    assert_equal "qq_string_content", gr.repository.keys[0]
    assert_equal /\(/, gr.repository.values[0].begin
  end
  
  def test_load_repository_multiple
    @grammar1['repository'] = {
      "qq_string_content" => 
      {
        "begin" => '\(',
        "end" => '\)',
        "patterns" => [{ "include" => '#qq_string_content' }]
      },
      "interpolated_ruby" => 
      {"patterns"=>
        [{"name"=>"source.ruby.embedded.source",
           "captures"=>{"0"=>{"name"=>"punctuation.section.embedded.ruby"}},
           "begin"=>"#\\{",
           "endif"=>"\\}",
           "patterns"=>
           [{"include"=>"#nest_curly_and_self"}, {"include"=>"$self"}]},
         {"name"=>"variable.other.readwrite.instance.ruby",
           "captures"=>{"1"=>{"name"=>"punctuation.definition.variable.ruby"}},
           "match"=>"(\#@)[a-zA-Z_]\\w*"}
        ]
      }
    }
    gr = Grammar.new(@grammar1)
    assert_equal 2, gr.repository.length
    assert_equal 2, gr.repository["interpolated_ruby"].length    
  end
  
  def test_pattern_lookup
    gr = Grammar.new(@grammar1)
    assert_equal /\b(if|while|for|return)\b/, gr.pattern('keyword.control.untitled').match
    assert_equal Regexp.new('"'), gr.pattern('string.quoted.double.untitled').begin
    assert_equal /\./, gr.pattern('constant.character.escape.untitled').match
  end
  
  def test_possible_patterns_from_no_scope
    gr = Grammar.new(@grammar2)
    pts = gr.possible_patterns(nil)
    assert_equal 1, pts.length
    assert_equal gr.pattern("keyword.control.untitled"), pts[0]
  end
  
  def test_possible_patterns_from_pattern
    gr = Grammar.new(@grammar1)
    pt = gr.pattern("string.quoted.double.untitled")
    pts = gr.possible_patterns(pt)
    assert_equal 1, pts.length
    assert_equal gr.pattern('constant.character.escape.untitled'), pts[0]
  end

  def test_possible_patterns_from_grammar_scope
    gr = Grammar.new(@grammar1)
    pts = gr.possible_patterns("source.untitled")
    assert_equal 2, pts.length
    assert_equal gr.pattern('string.quoted.double.untitled'), pts[1]
  end
  
  def test_possible_patterns_when_multiple_repository
    @grammar1['repository'] = {
      "qq_string_content" => 
      {
        "name" => "parens",
        "begin" => '\(',
        "end" => '\)',
        "patterns" => [{ "include" => '#qq_string_content' },
                       { "include" => '#interpolated_ruby' }]
      },
      "interpolated_ruby" => 
      {"patterns"=>
        [{"name"=>"source.ruby.embedded.source",
           "captures"=>{"0"=>{"name"=>"punctuation.section.embedded.ruby"}},
           "begin"=>"#\\{",
           "endif"=>"\\}",
           "patterns"=>
           [{"include"=>"#qq_string_content"}, {"include"=>"$self"}]},
         {"name"=>"variable.other.readwrite.instance.ruby",
           "captures"=>{"1"=>{"name"=>"punctuation.definition.variable.ruby"}},
           "match"=>"(\#@)[a-zA-Z_]\\w*"}
        ]
      }
    }
    gr = Grammar.new(@grammar1)
    pts = gr.possible_patterns("parens")
    assert_equal 3, pts.length
  end

  def test_possible_patterns_with_embedded_grammar
    Syntax.load_grammars
    gr = Syntax.grammar(:name => 'Ruby')
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
    assert smp.scope_tree.children[1].pattern.
      possible_patterns.map{|p| p.name}.include? "meta.tag.any.html"
  end
  
  def test_load_grammar
    grh = eval(IO.readlines("test/fixtures/ruby.plist").join)
    assert gr = Grammar.new(grh)
  end
end
