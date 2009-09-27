require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Application::Window do
  before do
    @window = Redcar::Application::Window.new
    @window.controller = RedcarSpec::WindowController.new
  end
  
  it "reports menu changes to the controller" do
    @window.controller.should_receive(:menu_changed)
    @window.menu = 1
  end
end