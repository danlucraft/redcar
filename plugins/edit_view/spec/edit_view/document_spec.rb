require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Document do
  class TestEditView
    attr_accessor :title

	include Redcar::Observable
    
    def reset_last_checked
    end
    
    def remove_all_annotations(o = nil); end
    def grammar; end

    def controller
      o = Object.new
      def o.method_missing(*_)
      end
      o
    end
  end
    
  class TestDocumentController
    def to_s
      @text
    end
    
    def text=(val)
      @text = val
    end
    
    def length
     @text.length
    end
    
    def get_range(from_here, to_here)
     @text[from_here, to_here]
    end
    
    def cursor_offset
      0
    end
    
    def line_at_offset(_)
      0
    end
    
    def line_count
      0
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
    
    def title
      "foo"
    end

    def make_a_change
      @text = "Changed content"
      notify_listeners(:change)
    end
  end
  
  before do
    @controller = TestDocumentController.new
    @controller.text = ""
    @doc = Redcar::Document.new(TestEditView.new)
    @doc.controller = @controller
    @mirror
  end
  
  it "should allow for retrieving all text" do
    @controller.text = "a\nb\n"
    @doc.get_all_text.should == "a\nb\n"
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
    
    it "should allow for a path method" do
      @doc.path.should == nil
      def @mirror.path
         'abc'
      end
      @doc.path.should == 'abc'    
      def @mirror.path
         nil
      end
      @doc.path.should == nil      
    end
    
  end
end






