
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
    if re.class.to_s.include? "Regexp"
      @re = re
    else
      if defined? Oniguruma
        @re = Oniguruma::ORegexp.new(re)
      else
        @re = Regexp.new(re)
      end
    end
    @replace = replace
  end
  
  def regexp_gsub(re, string, &blk)
    if re.class.to_s == "Oniguruma::ORegexp"
      re.gsub(string, &blk)
    else
      left = string.dup
      newstr = ""
      while left.length > 0
        md = re.match(left)
        if md
          newstr << md.pre_match
          r  = yield md
          newstr << r
          left = md.post_match
        else
          newstr << left
          left = ""
        end
      end
      newstr
    end
  end
  
  def regexp_sub(re, string, &blk)
    if re.class.to_s == "Oniguruma::ORegexp"
      re.sub(string, &blk)
    else
      md = re.match(string)
      if md
        r  = yield md
        string[md.begin(0)..(md.end(0)-1)] = r
      end
      string
    end
  end
  
  def grep(string)
    string = string.dup
    regexp_gsub(@re, string) do |md|
      parse_replace_string md, @replace.dup
    end
  end
  
  def rep(string)
    string = string.dup
    regexp_sub(@re, string) do |md|
      parse_replace_string md, @replace.dup
    end
  end
  
  def inspect
    "<RegexReplace: #{@re.inspect} -> #{@replace.inspect}>"
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
    replace.gsub!("\\u", "")
    replace.gsub!("\\l", "")
    replace.gsub!("\\U", "")
    replace.gsub!("\\L", "")
    replace.gsub!("\\E", "")
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
    
    def test_simple_blank
      rr = RegexReplace.new("blackbird", 
                            "laura")
      assert_equal "", rr.rep("")
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
    
    def test_lonely_upcase
      rr = RegexReplace.new("bl(ackb)ird", 
                            "\\u")
      assert_equal "foo  bar", rr.rep("foo blackbird bar")
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
  end
end
