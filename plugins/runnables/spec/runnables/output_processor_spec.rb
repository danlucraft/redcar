require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Redcar::Runnables::OutputProcessor do
  before do
    @processor = Redcar::Runnables::OutputProcessor.new
  end
  
  def processed
    @processor.process(@input)
  end
    
  it "should htmlize output" do
    @input = "Some text with & and <tags/>"
    processed.should == "Some text with &amp; and &lt;tags/>"
    
    @input = "  Some indenting"
    processed.should == "&nbsp;&nbsp;Some indenting"
  end
  
  it "should convert ANSI color to appropriate spans" do
    @input = "Some \e[31mred\e[0m text."
    processed.should == 'Some <span class="ansi-red">red</span> text.'
  end
  
  it "should preserve ANSI color between lines" do
    pending
  end
  
  it "should separate HTML output's head and body" do
    pending
  end
end