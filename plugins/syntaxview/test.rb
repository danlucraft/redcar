module Redcar::Tests; end

class Redcar::Tests::SyntaxViewTest < Test::Unit::TestCase
  include Redcar
  include Redcar.Syntax

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
  end
  
  def test_load_new_grammar
    assert Grammar.new(@grammar1)
    assert gr = Grammar.new(@lisp_grammar)
  end
end
