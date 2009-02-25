
require 'lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestTheme < Test::Unit::TestCase
  include Redcar
  
  def setup
    startup
    @theme_twilight = {
      "name"=>"Twilight",
      "uuid"=>"766026CB-703D-4610-B070-8DE07D967C5F",
      "settings"=>
      [{"settings"=>
         {"lineHighlight"=>"#FFFFFF08",
           "caret"=>"#A7A7A7",
           "background"=>"#141414",
           "selection"=>"#DDF0FF33",
           "invisibles"=>"#FFFFFF40",
           "foreground"=>"#F8F8F8"}},
       {"name"=>"Comment",
         "scope"=>"comment",
         "settings"=>{"fontStyle"=>"italic", "foreground"=>"#5F5A60"}},
       {"name"=>"Constant",
         "scope"=>"constant",
         "settings"=>{"foreground"=>"#CF6A4C"}},
       {"name"=>"Entity",
         "scope"=>"entity",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#9B703F"}},
       {"name"=>"Keyword",
         "scope"=>"keyword",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
       {"name"=>"Storage",
         "scope"=>"storage",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#F9EE98"}},
       {"name"=>"String",
         "scope"=>"string",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#8F9D6A"}},
       {"name"=>"Support",
         "scope"=>"support",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#9B859D"}},
       {"name"=>"Variable",
         "scope"=>"variable",
         "settings"=>{"foreground"=>"#7587A6"}},
       {"name"=>"Invalid – Deprecated",
         "scope"=>"invalid.deprecated",
         "settings"=>{"fontStyle"=>"italic underline", "foreground"=>"#D2A8A1"}},
       {"name"=>"Invalid – Illegal",
         "scope"=>"invalid.illegal",
         "settings"=>{"background"=>"#562D56BF", "foreground"=>"#F8F8F8"}},
       {"name"=>"-----------------------------------", "settings"=>{}},
       {"name"=>"Embedded Source",
         "scope"=>"text source",
         "settings"=>{"background"=>"#B0B3BA14"}},
       {"name"=>"Embedded Source (Bright)",
         "scope"=>"text.html.ruby source",
         "settings"=>{"background"=>"#B1B3BA21"}},
       {"name"=>"Entity inherited-class",
         "scope"=>"entity.other.inherited-class",
         "settings"=>{"fontStyle"=>"italic", "foreground"=>"#9B5C2E"}},
       {"name"=>"String embedded-source",
         "scope"=>"string source",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#DAEFA3"}},
       {"name"=>"String constant",
         "scope"=>"string constant",
         "settings"=>{"foreground"=>"#DDF2A4"}},
       {"name"=>"String.regexp",
         "scope"=>"string.regexp",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#E9C062"}},
       {"name"=>"String.regexp.«special»",
         "scope"=>
         "string.regexp constant.character.escape, string.regexp source.ruby.embedded, string.regexp string.regexp.arbitrary-repitition",
         "settings"=>{"foreground"=>"#CF7D34"}},
       {"name"=>"String variable",
         "scope"=>"string variable",
         "settings"=>{"foreground"=>"#8A9A95"}},
       {"name"=>"Support.function",
         "scope"=>"support.function",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#DAD085"}},
       {"name"=>"Support.constant",
         "scope"=>"support.constant",
         "settings"=>{"fontStyle"=>nil, "foreground"=>"#CF6A4C"}},
       {"name"=>"c C/C++ Preprocessor Line",
         "scope"=>"meta.preprocessor.c",
         "settings"=>{"foreground"=>"#8996A8"}},
       {"name"=>"c C/C++ Preprocessor Directive",
         "scope"=>"meta.preprocessor.c keyword",
         "settings"=>{"foreground"=>"#AFC4DB"}},
       {"name"=>"Doctype/XML Processing",
         "scope"=>
         "meta.tag.sgml.doctype, meta.tag.sgml.doctype entity, meta.tag.sgml.doctype string, meta.tag.preprocessor.xml, meta.tag.preprocessor.xml entity, meta.tag.preprocessor.xml string",
         "settings"=>{"foreground"=>"#494949"}},
       {"name"=>"Meta.tag.«all»",
         "scope"=>
         "declaration.tag, declaration.tag entity, meta.tag, meta.tag entity",
         "settings"=>{"foreground"=>"#AC885B"}},
       {"name"=>"Meta.tag.inline",
         "scope"=>
         "declaration.tag.inline, declaration.tag.inline entity, source entity.name.tag, source entity.other.attribute-name, meta.tag.inline, meta.tag.inline entity",
         "settings"=>{"foreground"=>"#E0C589"}},
       {"name"=>"css tag-name",
         "scope"=>"meta.selector.css entity.name.tag",
         "settings"=>{"foreground"=>"#CDA869"}},
       {"name"=>"css:pseudo-class",
         "scope"=>"meta.selector.css entity.other.attribute-name.tag.pseudo-class",
         "settings"=>{"foreground"=>"#8F9D6A"}},
       {"name"=>"css#id",
         "scope"=>"meta.selector.css entity.other.attribute-name.id",
         "settings"=>{"foreground"=>"#8B98AB"}},
       {"name"=>"css.class",
         "scope"=>"meta.selector.css entity.other.attribute-name.class",
         "settings"=>{"foreground"=>"#9B703F"}},
       {"name"=>"css property-name:",
         "scope"=>"support.type.property-name.css",
         "settings"=>{"foreground"=>"#C5AF75"}},
       {"name"=>"css property-value;",
         "scope"=>
         "meta.property-group support.constant.property-value.css, meta.property-value support.constant.property-value.css",
         "settings"=>{"foreground"=>"#F9EE98"}},
       {"name"=>"css @at-rule",
         "scope"=>"meta.preprocessor.at-rule keyword.control.at-rule",
         "settings"=>{"foreground"=>"#8693A5"}},
       {"name"=>"css additional-constants",
         "scope"=>
         "meta.property-value support.constant.named-color.css, meta.property-value constant",
         "settings"=>{"foreground"=>"#CA7840"}},
       {"name"=>"css constructor.argument",
         "scope"=>"meta.constructor.argument.css",
         "settings"=>{"foreground"=>"#8F9D6A"}},
       {"name"=>"diff.header",
         "scope"=>"meta.diff, meta.diff.header, meta.separator",
         "settings"=>
         {"fontStyle"=>"italic",
           "background"=>"#0E2231",
           "foreground"=>"#F8F8F8"}},
       {"name"=>"diff.deleted",
         "scope"=>"markup.deleted",
         "settings"=>{"background"=>"#420E09", "foreground"=>"#F8F8F8"}},
       {"name"=>"diff.changed",
         "scope"=>"markup.changed",
         "settings"=>{"background"=>"#4A410D", "foreground"=>"#F8F8F8"}},
       {"name"=>"diff.inserted",
         "scope"=>"markup.inserted",
         "settings"=>{"background"=>"#253B22", "foreground"=>"#F8F8F8"}},
       {"name"=>"Markup: List",
         "scope"=>"markup.list",
         "settings"=>{"foreground"=>"#F9EE98"}},
       {"name"=>"Markup: Heading",
         "scope"=>"markup.heading",
         "settings"=>{"foreground"=>"#CF6A4C"}}]}
    
  end
  
  def teardown
    shutdown
  end
  
  def test_load_theme
    th = Theme.new(@theme_twilight)
    assert th
    assert_equal "Twilight", th.name
    assert_equal "766026CB-703D-4610-B070-8DE07D967C5F", th.uuid
  end
  
  def test_theme_global_settings
    th = Theme.new(@theme_twilight)
    assert_equal({ "lineHighlight"=>"#FFFFFF08",
                   "caret"=>"#A7A7A7",
                   "background"=>"#141414",
                   "selection"=>"#DDF0FF33",
                   "invisibles"=>"#FFFFFF40",
                   "foreground"=>"#F8F8F8"}, th.global_settings)
  end

  def test_theme_scopes_with_simple_lookup
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"Comment",
           "scope"=>"comment",
           "settings"=>{"fontStyle"=>"italic", "foreground"=>"#5F5A60"}},
         { "name"=>"Keyword",
           "scope"=>"keyword",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    sc1 = Syntax::Scope.new :name => "keyword"
    sc2 = Syntax::Scope.new :name => "comment"
    assert_equal 1, th.settings_for_scope(sc1).length
    assert_equal 1, th.settings_for_scope(sc2).length
  end
  
  def test_theme_scopes_with_ors
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"Comment",
           "scope"=>"comment, keyword",
           "settings"=>{"fontStyle"=>"italic", "foreground"=>"#5F5A60"}},
         { "name"=>"Keyword",
           "scope"=>"keyword",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    sc1 = Syntax::Scope.new :name => "keyword"
    sc2 = Syntax::Scope.new :name => "comment"
    assert_equal 2, th.settings_for_scope(sc1).length
    assert_equal 1, th.settings_for_scope(sc2).length
  end
  
  def test_theme_scopes_with_ands
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"Comment",
           "scope"=>"comment keyword",
           "settings"=>{"fontStyle"=>"italic", "foreground"=>"#5F5A60"}},
         { "name"=>"Keyword",
           "scope"=>"keyword",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    sc1 = Syntax::Scope.new :name => "keyword"
    sc2 = Syntax::Scope.new :name => "comment"
    sc3 = Syntax::Scope.new :name => "comment.foobar.keyword"
    assert_equal 1, th.settings_for_scope(sc1).length
    assert_equal 0, th.settings_for_scope(sc2).length
    # 'comment keyword' matches comment.foobar.keyword?? don't think so.
  #  assert_equal 2, th.settings_for_scope(sc3).length
  end
  
  def test_theme_scopes_from_hierarchy
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"Comment",
           "scope"=>"source.ruby keyword",
           "settings"=>{"fontStyle"=>"italic", "foreground"=>"#5F5A60"}},
         { "name"=>"Keyword",
           "scope"=>"keyword",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
         { "name"=>"Keyword",
           "scope"=>"source.ruby keyword.if",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    sck = Syntax::Scope.new :name => "keyword"
    scki = Syntax::Scope.new :name => "keyword.if"
    
    scrk = Syntax::Scope.new :name => "source.ruby"
    scrki = Syntax::Scope.new :name => "source.ruby"
    sc1 = Syntax::Scope.new :name => "keyword"
    scrk.add_child(sc1)
    sc2 = Syntax::Scope.new :name => "keyword.if"
    scrki.add_child(sc2)
    
    sckf = Syntax::Scope.new :name => "keyword"
    scrl = Syntax::Scope.new :name => "source.ruby"
    sckf.add_child(scrl)
    assert_equal 1, th.settings_for_scope(sck).length
    assert_equal 1, th.settings_for_scope(scki).length
    assert_equal 2, th.settings_for_scope(sc1).length
    assert_equal 3, th.settings_for_scope(sc2).length
    
    # this is 'keyword source.ruby' and should not 
    # match 'source.ruby keyword'
    assert_equal 1, th.settings_for_scope(scrl).length
  end
  
  def test_difference
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"string-source",
           "scope"=>"source string - string source",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    s1 = Syntax::Scope.new :name => "source"
    s1.add_child(s2 = Syntax::Scope.new(:name => "string"))
    # 'source string'
    assert_equal 1, th.settings_for_scope(s2).length
    s2.add_child(s3 = Syntax::Scope.new(:name => "source"))
    # 'source string source'
    assert_equal 0, th.settings_for_scope(s3).length
    s3.add_child(s4 = Syntax::Scope.new(:name => "string"))
    # 'source string source string'
    assert_equal 1, th.settings_for_scope(s4).length
    s4.add_child(s5 = Syntax::Scope.new(:name => "source"))
    # 'source string source string source'
    assert_equal 0, th.settings_for_scope(s3).length
  end
  
  def test_tie_breaking
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"source.php",
           "scope"=>"source.php",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
         { "name"=>"string",
           "scope"=>"string",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    s1 = Syntax::Scope.new :name => "source.php"
    s1.add_child(s2 = Syntax::Scope.new(:name => "string.quoted"))
    # 1. Match the element deepest down in the scope e.g. 'string'
    # wins over 'source.php' when the scope is 'source.php string.quoted'.
    assert_equal "string", th.settings_for_scope(s2)[0]["name"]
    
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"string",
           "scope"=>"string",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
         { "name"=>"string.quoted",
           "scope"=>"string.quoted",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
         { "name"=>"source.php",
           "scope"=>"source.php",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    s1 = Syntax::Scope.new :name => "source.php"
    s1.add_child(s2 = Syntax::Scope.new(:name => "string.quoted"))
    # 2. Match most of the deepest element e.g. 'string.quoted' wins 
    # over 'string'.
    assert_equal "string.quoted", th.settings_for_scope(s2)[0]["name"]
    
    theme_example = {
      "name" => "example",
      "settings" => 
        [
         {"settings" => {
             "lineHighlight"=>"#FFFFFF08",
             "caret"=>"#A7A7A7",
             "background"=>"#141414",
             "selection"=>"#DDF0FF33",
             "invisibles"=>"#FFFFFF40",
             "foreground"=>"#F8F8F8"}},
         { "name"=>"source string",
           "scope"=>"source string",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}},
         { "name"=>"text source string",
           "scope"=>"text source string",
           "settings"=>{"fontStyle"=>nil, "foreground"=>"#CDA869"}}
        ]}
    th = Theme.new(theme_example)
    s1 = Syntax::Scope.new :name => "text"
    s1.add_child(s2 = Syntax::Scope.new(:name => "source.php"))
    s2.add_child(s3 = Syntax::Scope.new(:name => "string.quoted"))
    # Rules 1 and 2 applied again to the scope selector 
    # when removing the deepest element (in the case of a tie), 
    # e.g. text source string wins over source string.
    assert_equal "text source string", th.settings_for_scope(s3)[0]["name"]
  end
  
  def test_applicable
    th = Theme.new(@theme_twilight)
    scopes = [ "source.ruby",
               "string.unquoted.embedded.html.ruby",
               "text.html.embedded.ruby",
               "meta.tag.block.any.html",
               "string.quoted.double.html",
               "punctuation.definition.tag.html"]
    v1 = th.applicable?("declaration.tag, declaration.tag entity, meta.tag, meta.tag entity",
                        scopes)
    v2 = th.applicable?("string", scopes)
    assert v2[0] > v1[0]
    scopes = [ "text.html.basic",
               "meta.tag.inline.any.html",
               "string.quoted.double.html",
               "source.ruby.embedded.html",
               "punctuation.section.embedded.ruby"]
    assert_equal [3, [0, 1, 0, 0, 1]], th.applicable?("text source", scopes)
    assert_equal [2, [0, 0, 1, 0, 0]], th.applicable?("string", scopes)
    assert_equal [3, [0, 1, 1, 0, 0]], th.applicable?("string source - string", scopes)
  end
end
