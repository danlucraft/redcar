
module Redcar
  # When mixed into a class this module gives an interface for registering
  # listeners to particular events. Most Redcar models include this interface.
  #
  # == Examples
  #
  # Adding a listener
  #
  #   @obj.add_listener :MyHook do
  #     puts "code to run when MyHook is triggered"
  #   end
  #
  # Triggering a hook (from within the observed class)
  #
  #   notify_listeners(:MyHook)
  #
  # == Before and After Hooks
  #
  # You can attach code to run before and after an event:
  #
  #   @obj.add_listener :after => "MyHook" do
  #     puts "code to run after MyHook"
  #   end
  #
  #   @obj.add_listener :before => "MyHook" do
  #     puts "code to run before MyHook"
  #   end
  #
  # And then the :before blocks are guaranteed to run before the after blocks
  # and the blocks attached without specifying before and after.
  #
  # The event can also be triggered with a block:
  #
  #   notify_listeners :MyHook do
  #     puts "stuff that happens"
  #   end
  # 
  # then the output will be:
  #
  #  code to run before MyHook
  #  stuff that happens
  #  code to run after MyHook
  #
  # == Triggering with Objects
  # 
  # An object may pass an object or objects to it's listeners:
  #
  #   @obj.add_listener :NewTab do |new_tab|
  #     puts "do some stuff with the new tab: " + new_tab.to_s
  #   end
  #
  #   notify_listeners(:NewTab, new_tab)
  module Observable
    class UnknownEvent < RuntimeError; end
    ASPECTS = {
      :before => 0,
      :after => 1
    }
    
    # Attach a block to be called when any of the hooks in hooks are 
    # called.
    def add_listener(*event_names, &block)
      if event_names.first.is_a?(Hash)
        event_names.first.each do |aspect, event_name|
          events(event_name.to_s)[ASPECTS[aspect]] << block
        end
      else
        event_names.each do |event_name|
          events(event_name.to_s)[ASPECTS[:after]] << block
        end
      end
    end
    
    private
    
    def notify_listeners(event_name, *args)
      run_blocks(event_name, :before, args)
      yield if block_given?
      run_blocks(event_name, :after, args)
    end
    
    def run_blocks(event_name, aspect, args)
      blocks = events(event_name.to_s)[ASPECTS[aspect]]
      blocks.each { |b| b.call(*args) }
    end
    
    def events(event_name)
      @events ||= {}
      @events[event_name.to_s] ||= [[], []]
    end
  end
end