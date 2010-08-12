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

  it "should convert ANSI colors to span classes" do
    @input = "Some \e[31mred\e[0m text."
    processed.should == 'Some <span class="ansi-red">red</span> text.'
  end

  it "should convert ANSI bold to span class" do
    @input = "Some \e[1;31mbold red\e[0m text."
    processed.should == 'Some <span class="ansi-bold ansi-red">bold red</span> text.'
  end

  it "should include ANSI light variants" do
    @input = "Some \e[93mlight yellow\e[0m text."
    processed.should == 'Some <span class="ansi-light ansi-yellow">light yellow</span> text.'
  end

  it "should close out all spans on ANSI 0m" do
    @input = "Some \e[1;32mbold green\e[0;32mregular green\e[0m"
    processed.should == 'Some <span class="ansi-bold ansi-green">bold green<span class="ansi-regular ansi-green">regular green</span></span>'
  end

  it "should close out all spans at then end of the line" do
    @input = "Some \e[34mblue text"
    processed.should == 'Some <span class="ansi-blue">blue text</span>'
  end

  it "should continue color in next line" do
    @input = "Some \e[34mblue text"
    processed
    @input = "that spans lines\e[0m"
    processed.should == '<span class="ansi-blue">that spans lines</span>'
  end

  it "should separate HTML output's head and body" do
    # This is a planned feature but will get implemented in another branch.
    # The intention is to somehow handle cucumbers --format html for interactive
    # runnable output.
  end
end