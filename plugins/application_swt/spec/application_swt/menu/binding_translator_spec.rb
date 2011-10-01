require "spec_helper"

BindingTranslator = Redcar::ApplicationSWT::Menu::BindingTranslator
describe BindingTranslator do
  def check(key, value)
    BindingTranslator.key(key).should == value
  end
  
  describe "single modifiers" do
    it "translates Shift+letter" do
      check("Shift+N", Swt::SWT::SHIFT + 'N'[0])
      check("Shift+K", Swt::SWT::SHIFT + 'K'[0])
      check("Shift+P", Swt::SWT::SHIFT + 'P'[0])
    end

    it "translates Ctrl+letter" do
      check("Ctrl+T", Swt::SWT::CTRL + 'T'[0])
      check("Ctrl+2", Swt::SWT::CTRL + '2'[0])
    end

    it "translates Alt+letter" do
      check("Alt+B", Swt::SWT::ALT + 'B'[0])
    end

    it "translates Cmd+letter" do
      check("Cmd+X", Swt::SWT::COMMAND + 'X'[0])
    end
    
    it "translates F keys" do
      check("F3", Swt::SWT::F3)
      check("F4", Swt::SWT::F4)
    end
    
    it "translates arrow keys" do
      check("Right", Swt::SWT::ARROW_RIGHT)
      check("Left", Swt::SWT::ARROW_LEFT)
      check("Up", Swt::SWT::ARROW_UP)
      check("Down", Swt::SWT::ARROW_DOWN)
    end
    
    it "translates tab" do
      check("Tab", Swt::SWT::TAB)
    end

    it "translates home" do
      check("Home", Swt::SWT::HOME)
      check("Alt+Home", Swt::SWT::ALT + Swt::SWT::HOME)
      check("Shift+Home", Swt::SWT::SHIFT + Swt::SWT::HOME)
    end
    
    it "translates end" do
      check("End", Swt::SWT::END)
      check("Ctrl+End", Swt::SWT::CTRL + Swt::SWT::END)
      check("Cmd+End", Swt::SWT::COMMAND + Swt::SWT::END)
    end
  end

  describe "multiple modifiers" do
    it "translates Mod+Mod+letter" do
      check("Ctrl+Alt+W", Swt::SWT::CTRL + Swt::SWT::ALT + 'W'[0])
      check("Cmd+Alt+W", Swt::SWT::COMMAND + Swt::SWT::ALT + 'W'[0])
      check("Cmd+Shift+W", Swt::SWT::COMMAND + Swt::SWT::SHIFT + 'W'[0])
      check("Alt+Shift+W", Swt::SWT::ALT + Swt::SWT::SHIFT + 'W'[0])
    end
    
    it "translates Mod+Mod+Mod+letter" do
      check("Shift+Ctrl+Alt+W", Swt::SWT::SHIFT + Swt::SWT::CTRL + Swt::SWT::ALT + 'W'[0])
      check("Shift+Cmd+Alt+W", Swt::SWT::SHIFT + Swt::SWT::COMMAND + Swt::SWT::ALT + 'W'[0])
      check("Alt+Cmd+Shift+W", Swt::SWT::ALT + Swt::SWT::COMMAND + Swt::SWT::SHIFT + 'W'[0])
      check("Cmd+Alt+Shift+W", Swt::SWT::COMMAND + Swt::SWT::ALT + Swt::SWT::SHIFT + 'W'[0])
    end
  end
end