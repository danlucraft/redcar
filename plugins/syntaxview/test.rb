
module Redcar::Tests; end

ORegexp = Oniguruma::ORegexp

xml = IO.read(File.dirname(__FILE__)+"/../../textmate/Bundles/Ruby.tmbundle/Syntaxes/Ruby.plist")
plist = Redcar::Plist.xml_to_plist(xml)
$ruby_grammar = Redcar::Syntax::Grammar.new(plist[0])
xml2 = IO.read(File.dirname(__FILE__)+"/../../textmate/Bundles/HTML.tmbundle/Syntaxes/HTML.plist")
plist2 = Redcar::Plist.xml_to_plist(xml2)
$html_grammar = Redcar::Syntax::Grammar.new(plist2[0])

require File.dirname(__FILE__) + '/test/grammar_test.rb'
require File.dirname(__FILE__) + '/test/scope_test.rb'
require File.dirname(__FILE__) + '/test/parser_test.rb'

class Redcar::Tests::SyntaxViewTest < Test::Unit::TestCase
  include Redcar
  include Redcar::Syntax

  include GrammarTest
  include ScopeTest
  include ParserTest
  
  def setup
    setup_grammar_tests
    setup_scope_tests
    setup_parser_tests
  end
end
