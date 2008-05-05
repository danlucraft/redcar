
require 'rubygems'
if RUBY_VERSION == "1.9.0"
  module Oniguruma
    ORegexp = Regexp
  end
  ORegexp = Regexp
else
  require 'oniguruma'
  ORegexp = Oniguruma::ORegexp
end
require File.dirname(__FILE__) + '/ruby_extensions'

class RegexReplace
  COND_RE = /\(
                \?(\d+):
                (
                  (
                    \\\(|
                    \\\)|
                    \\:|
                    [^():]
                  )*
                )
                (
                  :
                  (
                    (
                      \\\(|
                      \\\)|
                      [^()]
                    )*
                  )
                )?
              \)
             /x
  
  def initialize(re, replace)
    @re = Oniguruma::ORegexp.new(re)
    @replace = replace
  end
  
  def grep(string)
    string = string.dup
    @re.gsub(string) do |md|
      parse_replace_string md, @replace.dup
    end
  end
  
  def rep(string)
    string = string.dup
    @re.sub(string) do |md|
      parse_replace_string md, @replace.dup
    end
  end
  
  private 
  
  def parse_replace_string(md, replace)
    replace.gsub!(COND_RE) do |match|
      if md[$1.to_i]
        $2.gsub("\\(", "(").gsub("\\)", ")")
      else
        if $4
          $5.gsub("\\(", "(").gsub("\\)", ")")
        else
          ""
        end
      end
    end
    replace.gsub!(/\$(\d+)/) do |match|
      md[$1.to_i]
    end
    replace.gsub!(/\\U(.*?)(\\E|$)/) do |match|
      $1.upcase
    end
    replace.gsub!(/\\L(.*?)(\\E|$)/) do |match|
      $1.downcase
    end
    replace.gsub!(/\\u(.)/) do |match|
      $1.upcase
    end
    replace.gsub!(/\\l(.)/) do |match|
      $1.downcase
    end
    replace.gsub!(/\\[abefnrstv]/) do |match|
      eval("\"\\#{match[-1..-1]}\"")
    end
    replace
  end
end

if $0 == __FILE__
  require 'test/unit'
  class TestRegexReplace < Test::Unit::TestCase
    def test_simple
      rr = RegexReplace.new("blackbird", 
                            "laura")
      assert_equal "foo laura bar", rr.rep("foo blackbird bar")
    end
    
    def test_simple_global
      rr = RegexReplace.new("blackbird", 
                            "laura")
      assert_equal "foo laura bar laura bar", rr.grep("foo blackbird bar blackbird bar")
    end
    
    def test_simple_single
      rr = RegexReplace.new("blackbird", 
                            "laura")
      assert_equal "foo laura bar blackbird bar", rr.rep("foo blackbird bar blackbird bar")
    end
    
    def test_escape_characters
      rr = RegexReplace.new("blackbird", 
                            "lau\\nr\\ta")
      assert_equal "foo lau\nr\ta bar blackbird bar", rr.rep("foo blackbird bar blackbird bar")
      
    end
    
    def test_full_match
      rr = RegexReplace.new("bl(ackb)ird", 
                            "laura$0")
      assert_equal "foo laurablackbird bar", rr.rep("foo blackbird bar")
    end
    
    def test_capture1
      rr = RegexReplace.new("bl(ackb)ird", 
                            "laura$1")
      assert_equal "foo lauraackb bar", rr.rep("foo blackbird bar")
    end
    
    def test_capture2
      rr = RegexReplace.new("bl(ackb)i(r)d", 
                            "$2laura$1")
      assert_equal "foo rlauraackb bar", rr.rep("foo blackbird bar")
    end
    
    def test_upcase_string
      rr = RegexReplace.new("bl(ackb)i(rd)", 
                            "\\U$2\\Elaura$1")
      assert_equal "foo RDlauraackb bar", rr.rep("foo blackbird bar")
    end
    
    def test_upcase_letter
      rr = RegexReplace.new("bl(ackb)i(rd)", 
                            "\\u$2laura$1")
      assert_equal "foo Rdlauraackb bar", rr.rep("foo blackbird bar")
    end
    
    def test_combination
      rr = RegexReplace.new("bl(ackb)i(rd)", 
                            "\\l\\U$2\\Elaura$1")
      assert_equal "foo rDlauraackb bar", rr.rep("foo blackbird bar")
    end
    
    def test_conditional
      rr = RegexReplace.new("(\\w+)|(\\W+)", 
                            "(?1:\\L$1\\E)(?2:\\(_)")
      assert_equal "textmate(_power(_editing", rr.grep("TextMate: Power Editing")
    end
    
    def test_conditional_with_alternative
      rr = RegexReplace.new("[[:alpha:]]+|( )", 
                            "(?1:_:\\L$0)")
      assert_equal "textmate:_power_editing", rr.grep("TextMate: Power Editing")
    end
    
    def test_performance
      st = Time.now
      1000.times do
        rr = RegexReplace.new("(\\w+)|(\\W+)", 
                              "(?1:\\L$1\\E)(?2:\\(_)")
        assert_equal "textmate(_power(_editing", rr.grep("TextMate: Power Editing")
      end
      te = Time.now
      assert (te-st) < 1.0
    end
  end
end
