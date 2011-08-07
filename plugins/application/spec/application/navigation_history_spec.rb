describe Redcar::NavigationHistory do
  module NavigationHistoryTest
    class TestEditView
      include Redcar::Observable
      attr_accessor :title
      
      def controller
        o = Object.new
        def o.method_missing(*_)
        end
        o
      end
    end
      
    class TestDocumentController
      attr_accessor :text, :cursor_offset
  
      def line_at_offset(_)
        0
      end
      
      def line_count
        0
      end
    end
    
    class TestMirror
      include Redcar::Observable
      attr_accessor :path
      
      def read
        "Test content"
      end
      
      def title
        "foo"
      end
    end
  end  
  
  class Redcar::NavigationHistory
    attr_accessor :current, :max_history_size
  end
    
  before do
    @controller = NavigationHistoryTest::TestDocumentController.new
    @controller.cursor_offset = 100
    @mirror = NavigationHistoryTest::TestMirror.new
    @mirror.path = "hoge.rb"
    @doc = Redcar::Document.new(NavigationHistoryTest::TestEditView.new)
    @doc.controller = @controller
    @doc.mirror = @mirror
    @history = Redcar::NavigationHistory.new
  end
  
  it "should save current cursor location" do
    @doc.cursor_offset.should == 100
    @history.size.should == 0
    @history.save(@doc)
    @history.size.should == 1
    @history[0][:path].should == "hoge.rb"
    @history[0][:cursor_offset].should == 100
  end
  
  it "can backward?" do
    @history.save(@doc)
    @history.can_backward?.should be_true
  end
  
  it "can forward?" do
    @history.save(@doc)
    @controller.cursor_offset = 50
    @history.save(@doc)
    @history.size.should == 2
    @history.current -= 2
    @history.can_forward?.should be_true
  end
  
  it "should not exceed max history size" do
    (@history.max_history_size + 10).times do
      @history.save(@doc)
      @controller.cursor_offset += 1
    end
    @history.size.should == @history.max_history_size
  end
  
  it "should delete old future when forward" do
    5.times do
      @history.save(@doc)
      @controller.cursor_offset += 1
    end
    @history.current = 2
    @history.save(@doc)
    @history.size.should == 3
  end
end