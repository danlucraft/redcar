
require "spec_helper"

include Redcar

describe AutoIndenter::Analyzer do
  class FakeDocument
    def initialize(string, tab_width, soft_tabs)
      @string = string
      @tab_width, @soft_tab = tab_width, soft_tabs
    end
    
    def get_line(ix)
      lines[ix] + "\n"
    end
    
    def lines
      @string.split("\n")
    end
    
    def indentation
      Document::Indentation.new(self, @tab_width, @soft_tabs)
    end
  end
  
  describe "with indentation rules like Ruby's" do
    def should_indent(src, options)
      simple_rules = AutoIndenter::Rules.new(/def/, /end/)
      analyzer = AutoIndenter::Analyzer.new(simple_rules, FakeDocument.new(src, 2, true), 2, true)
      analyzer.calculate_for_line(options[:line]).should == options[:indent]
    end
  
    it "should indent after an increase indent line" do
      should_indent(<<RUBY, :line => 1, :indent => 1)
def foo
# should be indented
RUBY
    end
    
    it "should decrease indent for a decrease indent line" do
      should_indent(<<RUBY, :line => 1, :indent => 1)
    p :adsf
    end # should be dedented
  p :adsf
RUBY
    end
  
    it "should set indent to match previous line" do
      should_indent(<<RUBY, :line => 3, :indent => 0)
def foo
  
end
  p :asdf # should be dedented
RUBY
    end
    
    it "should set indent to match previous line if an increase cancels out a decrease" do
      should_indent(<<RUBY, :line => 1, :indent => 0)
def foo
  end # should be dedented
RUBY
    end
  end
  
  describe "with indentation rules like C's" do
    def should_indent(options)
      simple_rules = AutoIndenter::Rules.new(
                        /\{/, 
                        /\}/, 
                        /^(?!.*;\s*\/\/).*[^\s;{}]\s*$/, 
                        /^\s*(\/\/|#).*$/
                      )
      analyzer = AutoIndenter::Analyzer.new(simple_rules, FakeDocument.new(source, 4, false), 4, false)
      analyzer.calculate_for_line(options[:line]).should == options[:indent]
    end
    
    def source
      t=<<-CSOURCE
int main (int argc, char const* argv[]) {
	while(true) {
		if(something())
			break;
#if 3
		play_awful_music();
		#else
		play_nice_music();
#endif
	}
	return 0;
}
 
if (foo)
  break;
 
if (foo)
{
  d;
 
CSOURCE
    end
    
    it "should set indentation on the first line to 0" do
      should_indent(:line => 0, :indent => 0)
    end
    
    it "should increase indent" do
      should_indent(:line => 1,  :indent => 1)
    end
    
    it "should increase indent (2)" do
      should_indent(:line => 2,  :indent => 2)
    end
    
    it "should indent next line" do
      should_indent(:line => 3,  :indent => 3)
      should_indent(:line => 14,  :indent => 1)
    end
    
    it "should leave unindented lines as they are" do
      should_indent(:line => 4,  :indent => 0)
      should_indent(:line => 6,  :indent => 2)
      should_indent(:line => 8,  :indent => 0)
    end
    
    it "should return to indent after unindented line" do
      should_indent(:line => 7,  :indent => 2)
    end
    
    it "should return to indent after unindented line, and next-line indent before that" do
      should_indent(:line => 5,  :indent => 2)
    end
    
    it "should decrease indent" do
      should_indent(:line => 9, :indent => 1)
      should_indent(:line => 11, :indent => 0)
    end
    
    it "should match indent" do
      should_indent(:line => 10, :indent => 1)
    end

    it "should not indent next lines if the next line matches the increase indent" do
      should_indent(:line => 17, :indent => 0)
    end

    it "should still increase the indent after an increase indent line after an increase next line" do
      should_indent(:line => 18, :indent => 1)
    end
  end
end  

