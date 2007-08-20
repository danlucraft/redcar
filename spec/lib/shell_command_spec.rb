
require 'spec/spec_helper'

context Redcar.Command, 'shell command' do
  before :all do
    Redcar.add_objects
    Redcar.output_style = :silent
    Redcar.load_image
  end
  
  before :each do
    @tab = Redcar.TextTab.new(Redcar.current_pane)
    @tab.focus
    @tab.load("spec/lib/fixtures/files/example.rb")
    @tab.sourceview.set_grammar(Redcar.SyntaxSourceView.grammar(:name => "Ruby"))
    @tab.select(10, 14)
    @shell_command = Redcar.Command.new(
                       Redcar.image["EE5F19BA-6C02-11D9-92BA-0011242E4184"])
  end
  
  after do
    @tab.close
  end
  
  def load_file(filename)
    @tab.load("spec/lib/fixtures/files/#{filename}.rb")
    @tab.sourceview.set_grammar(Redcar.SyntaxSourceView.grammar(:name => "Ruby"))
  end
  
  def update_grammar
    @tab.sourceview.set_grammar(Redcar.SyntaxSourceView.grammar(:name => "Ruby"))
    @tab.reparse_tab
  end
  
  specify "'verify ruby syntax' should execute properly" do
    # verify ruby syntax
    load_file("example")
    @tab.cursor = 21
    @shell_command = Redcar.Command.new(
                       Redcar.image["EE5F19BA-6C02-11D9-92BA-0011242E4184"])
    @tab.should_receive(:tooltip_at_cursor).with(<<END)
using ruby-1.8.5
-:3: syntax error, unexpected $end, expecting kEND
END
    @shell_command.execute
  end

  specify "'make destructive' should execute properly" do
    # make destructive
    @tab.contents = "puts 1\n[1, 2, 3].sort\nputs \"asd\"\n"
    update_grammar
    @tab.cursor = 21
    @shell_command = Redcar.Command.new(
                       Redcar.image["7F79BC8D-8A4F-4570-973B-05DFEC25747F"])
    @tab.should_receive(:insert_as_snippet).with("[1, 2, 3].sort!$0")
    @shell_command.execute
  end
  
  specify "'toggle quote style' should execute properly" do
    # make destructive
    @tab.contents = "puts 1\n[1, 2, 3].sort\nputs \"asd\"\n"
    update_grammar
    # @tab.cursor = 29
    @tab.select(27, 32)
    @shell_command = Redcar.Command.new(
                       Redcar.image["6519CB08-8326-4B77-A251-54722FFBFC1F"])
    @shell_command.execute
    @tab.contents.should == "puts 1\n[1, 2, 3].sort\nputs %{asd}\n"
  end
  
  specify "'execute line/selection as ruby' should execute properly" do
    # make destructive
    @tab.contents = "puts 1\n[1, 2, 3].reverse\nputs \"asd\"\n"
    update_grammar
    @tab.cursor = 24
    @shell_command = Redcar.Command.new(
                       Redcar.image["EE5F1FB2-6C02-11D9-92BA-0011242E4184"])
    @shell_command.execute
    @tab.contents.should == "puts 1\n[1, 2, 3].reverse [3, 2, 1]\nputs \"asd\"\n"
  end
  
  specify "'Insert Open/Close Tag' should execute properly" do
    # make destructive
    @tab.contents = "foo bar baz"
    update_grammar
    @tab.cursor = 6
    @shell_command = Redcar.Command.new(
                       Redcar.image["2ED44A32-C353-447F-BAE4-E3522DB6944D"])
    @tab.should_receive(:insert_as_snippet).with("<bar>$1</bar>")
    @shell_command.execute
  end
  
  specify "should set environment variables" do
    ENV['RUBYLIB'] = ""
    @shell_command.set_environment_variables
    ENV['RUBYLIB'].should == ":textmate/Support/lib"
    
    ENV['TM_BUNDLE_SUPPORT'].should == "textmate/Bundles/Ruby.tmbundle/Support"
    ENV['TM_CURRENT_LINE'].should == "  puts \"hi\"\n"
    ENV['TM_DIRECTORY'].should == "spec/lib/fixtures/files"
    ENV['TM_FILEPATH'].should == "spec/lib/fixtures/files/example.rb"
    ENV['TM_LINE_INDEX'].should == "6"
    ENV['TM_LINE_NUMBER'].should == "2"
    ENV['TM_SELECTED_TEXT'].should == "puts"
    ENV['TM_SCOPE'].should == "source.ruby"
    ENV['TM_SOFT_TABS'].should == "YES"
    ENV['TM_SUPPORT_PATH'].should == "textmate/Support"
    ENV['TM_TAB_SIZE'].should == "2"
    
    ENV['TM_RUBY'].should == "/usr/bin/ruby"
  end
  
  specify "should set environment variable TM_PROJECT_DIRECTORY"
  specify "should set environment variable TM_SELECTED_FILES"
  specify "should set environment variable TM_SELECTED_FILE"
  specify "should set context dependent environment variables"
end

# context Redcar.Command, 'shell command input' do
#   before :each do
#     @shell_command = Redcar.Command.new(example_shell_command)
#   end
  
#   specify "input should be piped into stdin"
# end

# context Redcar.Command, 'shell command output' do
  
#   specify "output should be collected from stdout"
# end

def example_shell_command
  {
    :tags => [:command],
    :file_capture_register => nil,
    :type => :shell,
    :output => nil,
    :capture_pattern => nil,
    :name => "Number List",
    :tab_trigger => nil,
    :capture_format_string => nil,
    :command => <<STR,
    #!/usr/bin/env ruby
    ENV['TM_SELECTED_TEXT'].to_s.each_line() { |line|
    	if(line =~ /^#/)
    		print("#\#{line}")
    	else
    		print("# \#{line}")
    	end
    }
STR
    :bundle_uuid => "E6858C0B-B2C9-4A39-A2D6-6D8360A923D0",
    :input => "selection",
    :created => Time.now,
    :line_capture_register => nil,
    :scope => "text.html.textile",
    :auto_scroll_output => nil,
    :fallback_input => nil,
    :visible => true,
    :before_running_command => "nop",
    :disable_output_auto_indent => nil,
    :activated_by_value => "control #",
    :enabled => true
  }
end
