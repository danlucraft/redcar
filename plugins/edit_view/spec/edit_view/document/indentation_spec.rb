
require "spec_helper"

describe Redcar::Document::Indentation do
  class MockDoc
    def initialize(string)
      @string = string
    end
    
    def get_line(ix)
      lines[ix] + "\n"
    end
    
    def offset_at_line(ix)
      return 0 if ix == 0
      lines[0..(ix - 1)].join("\n").length + 1
    end
    
    def delim
      "\n"
    end
    
    private
    
    def lines
      @string.split("\n")
    end
  end
  
  describe "#get_level" do
    it "should report indent correctly" do
      ind = Redcar::Document::Indentation.new(MockDoc.new(<<RUBY), 4, false)
def foo
	p :foo
    p :bar
  	p :baz
  		p :qux
  	  	p :qux
  	   
RUBY
      ind.get_level(0).should == 0
      ind.get_level(1).should == 1
      ind.get_level(2).should == 1
      ind.get_level(3).should == 1
      ind.get_level(4).should == 2
      ind.get_level(5).should == 2
      ind.get_level(6).should == 1
    end
  end
  
  describe "#set_level" do
    describe "with soft tabs" do
      it "should set indent correctly from no indent" do
        @doc = MockDoc.new(<<RUBY)
def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, true)
        @doc.should_receive(:replace).with(0, 0, "    ")
        ind.set_level(0, 1)
      end
  
      it "should set indent correctly from no indent (2)" do
        @doc = MockDoc.new(<<RUBY)
def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, true)
        @doc.should_receive(:replace).with(0, 0, "        ")
        ind.set_level(0, 2)
      end
  
      it "should set indent correctly resetting previous indent" do
        @doc = MockDoc.new(<<RUBY)
        def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, true)
        @doc.should_receive(:replace).with(0, 8, "    ")
        ind.set_level(0, 1)
      end
    end
    
    describe "with hard tabs" do
      it "should set indent correctly from no indent" do
        @doc = MockDoc.new(<<RUBY)
def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, false)
        @doc.should_receive(:replace).with(0, 0, "\t")
        ind.set_level(0, 1)
      end
  
      it "should set indent correctly resetting previous indent" do
        @doc = MockDoc.new(<<RUBY)
		def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, false)
        @doc.should_receive(:replace).with(0, 2, "\t")
        ind.set_level(0, 1)
      end
      
      it "should set indent correctly (2) from no indent" do
        @doc = MockDoc.new(<<RUBY)
def foo
RUBY
        ind = Redcar::Document::Indentation.new(@doc, 4, false)
        @doc.should_receive(:replace).with(0, 0, "\t\t")
        ind.set_level(0, 2)
      end
    end
    
  end
end

