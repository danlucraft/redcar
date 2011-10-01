require "spec_helper"

describe Redcar::Sensitive do
  class ExampleModel
    include Redcar::Observable
    
    def trigger_event(event_name, *args)
      notify_listeners(event_name, *args)
    end
  end

  before do
    Redcar::Sensitivity.all.clear
    
    @ex = ExampleModel.new
    
    Redcar::Sensitivity.new(:raining, @ex, true, [:new_tab]) do
      @open_tab == true
    end
    
    Redcar::Sensitivity.new(:is_tuesday, @ex, true, [:midnight]) do
      @is_tuesday == true
    end
  end
  
  def deactivate_open_tab
    @open_tab = false
    @ex.trigger_event(:new_tab)
  end
  
  def activate_open_tab
    @open_tab = true
    @ex.trigger_event(:new_tab)
  end
  
  def deactivate_is_tuesday
    @is_tuesday = false
    @ex.trigger_event(:is_tuesday)
  end
  
  def activate_is_tuesday
    @is_tuesday = true
    @ex.trigger_event(:is_tuesday)
  end
    
  describe "a singly sensitive object" do
    class SensitiveObject
      include Redcar::Sensitive
      
      def active_changed(value)
        @my_activeness_changed = true
      end
      
      def initialize
        sensitize :raining
      end
      attr_accessor :my_activeness_changed
    end

    before do
      @obj = SensitiveObject.new
    end
    
    it "should be active by default" do
      @obj.should be_active
    end
    
    it "becomes inactive when its sensitivity becomes inactive" do
      deactivate_open_tab
      @obj.should_not be_active
    end
    
    it "becomes active when its sensitivity becomes active" do
      deactivate_open_tab
      @obj.should_not be_active
      activate_open_tab
      @obj.should be_active
    end
    
    it "knows when it's sensitivity has changed" do
      deactivate_open_tab
      @obj.my_activeness_changed.should be_true
    end
  end
  
  describe "a multiple sensitive object" do
    class MultiplySensitiveObject
      include Redcar::Sensitive
      def initialize
        sensitize :raining, :is_tuesday
      end

      def active_changed(value)
        @my_activeness_changed = true
      end
      
      attr_accessor :my_activeness_changed
    end

    before do
      @obj = MultiplySensitiveObject.new
    end
    
    it "should be active by default" do
      @obj.should be_active
    end
    
    it "becomes inactive when one of its sensitivities becomes inactive" do
      deactivate_open_tab
      @obj.should_not be_active
      @obj.my_activeness_changed.should be_true
    end
    
    it "remains inactive when both of its sensitivities becomes inactive" do
      deactivate_open_tab
      @obj.my_activeness_changed = false
      deactivate_is_tuesday
      @obj.should_not be_active
      @obj.my_activeness_changed.should be_false
    end
    
    it "remains inactive when one of its sensitivities becomes active again" do
      deactivate_open_tab
      deactivate_is_tuesday
      @obj.my_activeness_changed = false
      activate_is_tuesday
      @obj.should_not be_active
      @obj.my_activeness_changed.should be_false
    end

    it "becomes active when both of its sensitivities become active again" do
      deactivate_open_tab
      deactivate_is_tuesday
      activate_is_tuesday
      @obj.my_activeness_changed = false
      activate_open_tab
      @obj.should be_active
      @obj.my_activeness_changed.should be_true
    end
  end
    
  describe "a sensitive class" do
    it "reports its sensitivities" do
      s = SensitiveObject.new.sensitivities
      s.length.should == 1
      s.first.name.should == :raining
      
      s = MultiplySensitiveObject.new.sensitivities
      s.length.should == 2
      s.map {|s| s.name}.should == [:raining, :is_tuesday]
    end
  end
end



