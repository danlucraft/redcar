
require 'spec/spec_helper'

def example_inline_command
  Redcar.Command.new({
          :uuid => "12345", 
          :name => "Test Command",
          :type => :inline,
          :fallback_input => :none,
          :input => :none,
          :output => :discard,
          :activated_by => :key_combination,
          :scope_selector => "",
          :command => "$inline_output = 1234",
          :enabled => true,
          :visible => true,
          :tooltip => "",
          :icon => "none"      
        })
end

context Redcar.Command, 'inline command' do
  before :each do 
    $inline_output = nil
    @inline_command = example_inline_command
  end
  
  specify "should execute correctly" do
    @inline_command.execute
    $inline_output.should == 1234
  end
end

context Redcar.Command, "inline command input" do 
  before(:all) do
    Redcar.add_objects
    Redcar::App.output_style = :silent
  end

  before(:each) do
    @tab = Redcar.TextTab.new(Redcar.current_pane)
    @tab.focus
    @str = "foo\nbar\nbaz\n"
    @tab.contents = @str
    @tab.cursor = 5
    @inline_command = example_inline_command
  end
  
  after do
    @tab.close
  end
  
  specify "should get the document as input" do
    @inline_command.input_by_type(:document).should == @str
  end
  
  specify "should get a line as input" do
    @inline_command.input_by_type(:line).should == "bar\n"
  end
  
  specify "should get a word as input" do
    @inline_command.input_by_type(:word).should == "bar"
  end
  
  specify "should get a character as input" do
    @inline_command.input_by_type(:character).should == "a"
  end
  
  specify "should get the scope as input" do
    @tab.replace "puts \"hello\""
    @tab.cursor = 7
    Redcar.SyntaxSourceView.load_grammars
    @tab.textview.set_grammar(Redcar.SyntaxSourceView.grammar(:name => 'Ruby'))
    @inline_command.input_by_type(:scope).should == "\"hello\""
  end
  
  specify "should get the selected text as input" do
    @tab.select(4, 7)
    @inline_command.input_by_type(:selected_text).should == "bar"
  end
  
  specify "should go to fallback input if primary input is not available" do
    @inline_command.def[:input] = :selected_text
    @inline_command.def[:fallback_input] = :line
    @tab.select(4, 7)
    @inline_command.get_input.should == "bar"
    @tab.cursor = 1
    @inline_command.get_input.should == "foo\n".chars
  end
end

context Redcar.Command, "inline command output" do
  
  before(:all) do
    Redcar.add_objects
    Redcar::App.output_style = :silent
  end

  before(:each) do
    @tab = Redcar.TextTab.new(Redcar.current_pane)
    @tab.focus
    @str = "foo\nbar\nbaz\n"
    @tab.contents = @str
    @tab.cursor = 5
    @inline_command = example_inline_command
  end
  
  specify 'should replace document' do
    @inline_command.direct_output(:replace_document, "foo")
    @tab.contents.should == "foo"
  end
  
  specify 'should replace line' do 
    @inline_command.direct_output(:replace_line, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should replace selected text' do
    @tab.select(4, 7)
    @inline_command.direct_output(:replace_selected_text, "foo")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should insert at cursor ("Insert As Text")' do
    @inline_command.direct_output(:insert_as_text, "qux")
    @tab.contents.should == @str.insert(5, "qux")
  end

  specify 'should insert as snippet'
  specify 'should show as HTML'
  
  specify 'should show as tooltip' do
    @tab.should_receive(:tooltip_at_cursor).with("corge")
    @inline_command.direct_output(:show_as_tool_tip, "corge")
  end
  
  specify 'should create new document (needs fixing of panes and tabs malarky, but should work)'# do
#     p Redcar.current_window.all_tabs.map(&:name)
#     before = Redcar.current_window.all_tabs.length
#     @inline_command.direct_output(:create_new_document, "corge")
#     p Redcar.current_window.all_tabs.map(&:name)
#     Redcar.tab["output: "+@inline_command.def[:name]].should_not be_nil
#     p Redcar.current_window.all_tabs.map(&:name)
#     Redcar.current_window.all_tabs.length.should == before+1
#   end
  
  specify 'should replace input, when input is primary input' do
    @inline_command.def[:input] = :line
    @inline_command.direct_output(:replace_input, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should replace input, when input is fallback input' do
    @inline_command.def[:input] = :selected_text
    @inline_command.def[:fallback_input] = :line
    @inline_command.direct_output(:replace_input, "foo\n")
    @tab.contents.should == "foo\nfoo\nbaz\n"
  end
  
  specify 'should insert after input, when input is primary input' do
    @inline_command.def[:input] = :line
    @inline_command.direct_output(:insert_after_input, "foo\n")
    @tab.contents.should == "foo\nbar\nfoo\nbaz\n"
  end
  
  specify 'should insert after input, when input is fallback input' do
    @inline_command.def[:input] = :selected_text
    @inline_command.def[:fallback_input] = :line
    @inline_command.direct_output(:insert_after_input, "foo\n")
    @tab.contents.should == "foo\nbar\nfoo\nbaz\n"
  end
  
end
