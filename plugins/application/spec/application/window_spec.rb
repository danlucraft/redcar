require "spec_helper"

describe Redcar::Window do
  
  describe "a new window" do
    before do
      @window = Redcar::Window.new
    end  
    
    it "notifies the controller that the menu has changed" do
      @called_menu_changed = false
      @window.add_listener(:refresh_menu) do
        @called_menu_changed = true
      end
      @window.refresh_menu
      @called_menu_changed.should be_true
    end

    it "has a treebook" do
      @window.treebook.should be_an_instance_of(Redcar::Treebook)
    end
    
  end
end