
require 'spec/spec_helper'

context Redcar::Command, "when collecting input for command" do 
  before(:all) do
    Redcar.add_objects
    Redcar.output_style = :silent
  end

  before(:each) do
    @tab = Redcar::TextTab.new(Redcar.current_pane)
    @tab.focus
    @str = "foo\nbar\nbaz\n"
    @tab.contents = @str
    @tab.cursor = 5
    @command = Redcar::Command.new(
      {
          :uuid => "12345", 
          :name => "Test Command",
          :type => :inline,
          :fallback_input => :none,
          :input => :none,
          :output => :discard,
          :activated_by => :key_combination,
          :scope_selector => "",
          :command => "",
          :enabled => true,
          :visible => true,
          :tooltip => "",
          :icon => "none"      
        })
                             
  end
  
  after do
    @tab.close
  end
  
  specify "should get the document as input" do
    @command.input_by_type(:document).should == @str
  end
  
  specify "should get a line as input" do
    @command.input_by_type(:line).should == "bar\n"
  end
  
  specify "should get a word as input" do
    @command.input_by_type(:word).should == "bar"
  end
  
  specify "should get a character as input" do
    @command.input_by_type(:character).should == "a"
  end
  
  specify "should get the scope as input" do
    @tab.replace "puts \"hello\""
    @tab.cursor = 7
    Redcar::Syntax.load_grammars
    @tab.textview.set_grammar(Redcar::Syntax.grammar(:name => 'Ruby'))
    @command.input_by_type(:scope).should == "\"hello\""
  end
  
  specify "should get the selected text as input" do
    @tab.select(4, 7)
    @command.input_by_type(:selected_text).should == "bar"
  end
  
  specify "should go to fallback input if primary input is not available" do
    @command.def[:input] = :selected_text
    @command.def[:fallback_input] = :line
    @tab.select(4, 7)
    @command.get_input.should == "bar"
    @tab.cursor = 1
    @command.get_input.should == "foo\n".chars
  end
end

context Redcar::Command, "when using output of command" do
  
  before(:all) do
    Redcar.add_objects
    Redcar.output_style = :silent
  end

  before(:each) do
    @tab = Redcar::TextTab.new(Redcar.current_pane)
    @tab.focus
    @str = "foo\nbar\nbaz\n"
    @tab.contents = @str
    @tab.cursor = 5
    @command = Redcar::Command.new(
      {
          :uuid => "12345", 
          :name => "Test Command",
          :type => :inline,
          :fallback_input => :none,
          :input => :none,
          :output => :discard,
          :activated_by => :key_combination,
          :scope_selector => "",
          :command => "",
          :enabled => true,
          :visible => true,
          :tooltip => "",
          :icon => "none"      
        })                
  end
  
  specify 'should replace document' do
    @command.direct_output(:replace_document, "foo")
    @tab.contents.should == "foo"
  end
  
  specify 'should replace line' do 
    @command.direct_output(:replace_line, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should replace selected text' do
    @tab.select(4, 7)
    @command.direct_output(:replace_selected_text, "foo")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should insert at cursor ("Insert As Text")' do
    @command.direct_output(:insert_as_text, "qux")
    @tab.contents.should == @str.insert(5, "qux")
  end

  specify 'should insert as snippet'
  specify 'should show as HTML'
  
  specify 'should show as tooltip' do
    @tab.should_receive(:tooltip_at_cursor).with("corge")
    @command.direct_output(:show_as_tool_tip, "corge")
  end
  
  specify 'should create new document (needs fixing of panes and tabs malarky, but should work)'# do
#     p Redcar.current_window.all_tabs.map(&:name)
#     before = Redcar.current_window.all_tabs.length
#     @command.direct_output(:create_new_document, "corge")
#     p Redcar.current_window.all_tabs.map(&:name)
#     Redcar.tab["output: "+@command.def[:name]].should_not be_nil
#     p Redcar.current_window.all_tabs.map(&:name)
#     Redcar.current_window.all_tabs.length.should == before+1
#   end
  
  specify 'should replace input, when input is primary input' do
    @command.def[:input] = :line
    @command.direct_output(:replace_input, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should replace input, when input is fallback input' do
    @command.def[:input] = :selected_text
    @command.def[:fallback_input] = :line
    @command.direct_output(:replace_input, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should insert after input, when input is primary input' do
    @command.def[:input] = :line
    @command.direct_output(:insert_after_input, "foo\n")
    @tab.contents.should == "foo\nbar\nfoo\nbaz\n"
  end
  
  specify 'should insert after input, when input is fallback input' do
    @command.def[:input] = :selected_text
    @command.def[:fallback_input] = :line
    @command.direct_output(:insert_after_input, "foo\n")
    @tab.contents.should == "foo\nbar\nfoo\nbaz\n"
  end
  
end
