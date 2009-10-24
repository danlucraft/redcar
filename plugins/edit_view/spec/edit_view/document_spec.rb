require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Document do
  class TestDocumentController
    def to_s
      @text
    end
    
    def text=(val)
      @text = val
    end
  end
  
  class TestMirror
    include Redcar::Observable
    
    def read
      @text || "Test content"
    end
    
    def commit(val)
      @text = val
    end

    def make_a_change
      @text = "Changed content"
      notify_listeners(:change)
    end
  end
  
  before do
    @controller = TestDocumentController.new
    @controller.text = ""
    @doc = Redcar::Document.new(nil)
    @doc.controller = @controller
    @mirror
  end
  
  describe "with no mirror" do
    it "reads from the mirror when it is set" do
      @doc.mirror = TestMirror.new
      @controller.to_s.should == "Test content"
    end
  end
  
  describe "with a mirror" do
    before do
      @mirror = TestMirror.new
      @doc.mirror = @mirror
    end
    
    it "responds to changes from the mirror" do
      @mirror.make_a_change
      @controller.to_s.should == "Changed content"
    end
    
    it "saves by committing to the mirror" do
      @controller.text = "Saved text"
      @doc.save!
      @mirror.read.should == "Saved text"
    end
  end
end






