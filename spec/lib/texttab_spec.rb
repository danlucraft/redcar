
require 'lib/redcar'

describe Redcar::TextTab do
  before do
    Redcar.add_objects
    Redcar::App.output_style = :silent
    @tab = Redcar::TextTab.new(Redcar.current_pane)
    @str = "foo\nbar\nbaz\n"
    @tab.contents = @str
  end
  
  after do
    @tab.close
  end
  
  it do
    @tab.should be_an_instance_of(Redcar::TextTab)
  end
  
  it 'should expose text through \'contents(=)\'' do
    @tab.buffer.text.should == @str
  end
  
  it 'should expose text through \'get_text\' and \'set_text\'' do
    @tab.get_text(0..2).should == "foo"
    @tab.set_text(0..2, "qux")
    @tab.buffer.text.should == "qux\nbar\nbaz\n"
  end
  
  it "should expose text through 'text[]' and 'text[]='" do
    @tab.text[0..2].should == "foo"
    @tab.text[0..2] = "qux"
    @tab.buffer.text.should == "qux\nbar\nbaz\n"
  end
  
  it 'should undo text operations' do
    @tab.undo
    @tab.contents.should == ""
  end
  
  it 'should redo text operations' do
    @tab.undo
    @tab.redo
    @tab.contents.should == @str
  end
end
