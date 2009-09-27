require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Application::Window do
  before do
    @window = Redcar::Application::Window.new
    @window.controller = RedcarSpec::WindowController.new
  end
end