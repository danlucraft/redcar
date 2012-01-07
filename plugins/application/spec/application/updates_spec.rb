
require "spec_helper"

describe Redcar::Application::Updates do

  describe "comparing versions logic" do

    it "0.10 = 0.10" do
      Redcar::Application::Updates.newer_than?([0, 10], [0, 10]).should be_false
    end
    
    it "0.10.0 = 0.10" do
      Redcar::Application::Updates.newer_than?([0, 10, 0], [0, 10]).should be_false
    end

    it "0.10 = 0.10.0" do
      Redcar::Application::Updates.newer_than?([0, 10], [0, 10, 0]).should be_false
    end
    
    it "0.10.1 > 0.10" do
      Redcar::Application::Updates.newer_than?([0, 10, 1], [0, 10]).should be_true
    end
    
    it "0.11 > 0.10" do
      Redcar::Application::Updates.newer_than?([0, 11], [0, 10]).should be_true
    end

    it "0.11.1 > 0.10" do
      Redcar::Application::Updates.newer_than?([0, 11, 1], [0, 10]).should be_true
    end

    it "0.11 > 0.10.1" do
      Redcar::Application::Updates.newer_than?([0, 11], [0, 10, 1]).should be_true
    end
    
    it "0.11.1 > 0.10.1" do
      Redcar::Application::Updates.newer_than?([0, 11, 1], [0, 10, 1]).should be_true
    end

    it "0.9 < 0.10" do
      Redcar::Application::Updates.newer_than?([0, 9], [0, 10]).should be_false
    end

    it "0.9.1 < 0.10" do
      Redcar::Application::Updates.newer_than?([0, 9, 1], [0, 10]).should be_false
    end

    it "0.9 < 0.10.1" do
      Redcar::Application::Updates.newer_than?([0, 9], [0, 10, 1]).should be_false
    end

  end
end