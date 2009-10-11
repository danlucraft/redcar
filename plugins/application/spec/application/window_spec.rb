require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Window do
  
  before do
    @window = Redcar::Window.new
    @called_menu_changed = false
    @window.add_listener(:menu_changed) do
      @called_menu_changed = true
    end
  end  
    
  it "notifies the controller that the menu has changed" do
    @window.menu = 1
    @called_menu_changed.should be_true
  end
end