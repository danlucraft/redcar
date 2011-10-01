
require "spec_helper"

describe Redcar::Observable do
  class SeeMe
    include Redcar::Observable
    
    def trigger_event(event, *args, &block)
      notify_listeners(event, *args, &block)
    end
  end
  
  before do
    @obj = SeeMe.new
    @value = nil
  end
  
  describe "without any listeners" do
    it "attaches and triggers an event" do
      @obj.add_listener(:christmas) do
        @value = 101
      end
      @obj.trigger_event(:christmas)
      @value.should == 101
    end
  
    it "triggers an event with a block" do
      @obj.trigger_event(:christmas) do
        @value = 10
      end
      @value.should == 10
    end
  
    it "attaches and triggers to multiple events" do
      @obj.add_listener :HookTestHook, :HookTestHook2 do
        @value = 34
      end
      @value.should be_nil
      @obj.trigger_event :HookTestHook
      @value.should == 34
      @value = nil
      @obj.trigger_event :HookTestHook2
      @value.should == 34
    end
  
    it "calls a before block first" do
      @value = 1
      @obj.add_listener :before => :HookTestHook do 
        @value = 10
      end
      @obj.trigger_event :HookTestHook do
        @value *= 5
      end
      @value.should == 50
    end

    it "calls an after block after" do
      @value = nil
      @obj.add_listener :after => :HookTestHook do 
        @value *= 5
      end
      @obj.trigger_event :HookTestHook do
        @value = 10
      end
      @value.should == 50
    end
  
    it "passes an object through to the block" do
      @obj.add_listener :HookTestHook do |str|
        str.reverse!
      end
      str = "Hello!"
      @obj.trigger_event :HookTestHook, str
      str.should == "!olleH"
    end

    it "passes multiple objects through to the block" do
      @obj.add_listener :HookTestHook do |str1, str2|
        str1.replace(str1 + str2)
      end
      str1 = "Hel"
      str2 = "lo!"
      @obj.trigger_event :HookTestHook, str1, str2
      str1.should == "Hello!"
    end
  end
  
  describe "with a listener" do
    before do
      @handler = @obj.add_listener(:christmas) do
        @value = 101
      end
    end
    
    it "attaches and triggers an event" do
      @obj.remove_listener(@handler)
      @obj.trigger_event(:christmas)
      @value.should be_nil
    end
  end
end




