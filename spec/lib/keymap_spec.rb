
require 'lib/redcar'

describe Redcar.Keymap do
  before :all do
    Redcar.add_objects
    Redcar::App.output_style = :silent
    tab = Redcar.new_tab
    tab.focus
    tab.textview.has_focus = true
  end
  
  before :each do
    Redcar.Keymap.clear
    $output = 0
    @a = Redcar.Keymap.new("Test A")
  end

  it 'should create a keymap' do
    Redcar.Keymap.all.include?(@a).should be_true
  end
  
  it 'should attach a keymap to the global keymap point' do
    @a.push_before(:global)
  end
  
  it 'should execute the command' do
    @a.push_before(:global)
    @a.add_command(test_command.dup)
    Redcar.Keymap.execute_keystroke("control a")
    $output.should == 123
  end
  
  it 'should attach a keymap to a tab class' do
    @b = Redcar.Keymap.new("Test B")
    @b.push_before(Redcar.TextTab)
    c = test_command.dup
    c[:command] = <<RUBY
$output = 1234
RUBY
    c[:activated_by_value] = "control b"
    @b.add_command(c)
    Redcar.Keymap.execute_keystroke("control b")
    $output.should == 1234
  end
  
  it 'should attach a keymap to a tab instance' do
    c = Redcar.Keymap.new("Test C")
    c.push_before(Redcar.current_tab)
    com = test_command.dup
    com[:command] = <<RUBY
$output = 12342
RUBY
    com[:activated_by_value] = "control c"
    c.add_command(com)
    Redcar.Keymap.execute_keystroke("control c")
    $output.should == 12342
  end
  
#   it 'should attach a keymap to a widget class' do
#     d = Redcar.Keymap.new("Test D")
#     d.push_before(Redcar.SyntaxSourceView)
#     c = test_command.dup
#     c[:command] = "$output = 123425"
#     c[:activated_by_value] = "control d"
#     d.add_command(c)
#     Redcar.Keymap.execute_keystroke("control d")
#     $output.should == 123425
#   end
  
  def test_command
    {
      :type => :inline,
      :scope_selector => "",
      :enabled => true,
      :sensitive => :nothing,
      :uuid => "82b411c0-14ed-012a-209b-000ae4ee635c",
      :name => "Test Command",
      :tooltip => "",
      :activated_by => :key_combination,
      :visible => true,
      :input => :none,
      :activated_by_value => "control a",
      :output => :discard,
      :command => <<RUBY,
$output = 123
RUBY
      :fallback_input => :none,
      :icon => :none
    }
  end
end
