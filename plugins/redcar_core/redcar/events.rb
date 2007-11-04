module Redcar
  # Returns the filename of the caller of the caller of this method.
  def self.caller_file(callstack)
    callstack.each do |callline|
      val = callline.split(":").first.split("/")[-2..-1].join("/")
      return val unless val.include? "events.rb"
    end
  end
  
  # Hook a block to be called when any of the events in @events@ are 
  # called.
  def self.hook(*events, &block)
    events.each do |event|
      event = event.to_s
      if event[0..6] == "before_"
        hooks = ($BUS['/redcar/events/'+event[7..-1].to_s+'/before'].data ||= [])
      elsif event[0..5] == "after_"
        hooks = ($BUS['/redcar/events/'+event[6..-1].to_s+'/after'].data ||= [])
      else 
        hooks = ($BUS['/redcar/events/'+event.to_s+'/after'].data ||= [])
      end
      hooks << {:block => block, :caller => caller_file(caller)}
    end
  end
  
  # Remove all the hooks that the calling file has set.
  def self.clear_hooks(who=nil)
    who = caller_file(caller) unless who
    $BUS['/redcar/events'].each_slot do |slot|
      slot['before'].data = (slot['before'].data||[]).select {|hk| hk[:caller] != who}
      slot['after'].data = (slot['after'].data||[]).select {|hk| hk[:caller] != who}
    end
  end
  
  def self.is_before_or_after_event?(name) # :nodoc:
    name.to_s[0..6] == "before_" or name.to_s[0..5] == "after_"
  end
  
  # Call an event. Has an optional object (to pass into the hooked
  # blocks) and an optional block.
  def self.event(name, object=nil)
    ($BUS['/redcar/events/'+name.to_s+'/before'].data||[]).each do |hash|
      hash[:block].call(object)
    end

    yield if block_given?

    ($BUS['/redcar/events/'+name.to_s+'/after'].data||[]).each do |hash|
      hash[:block].call(object)
    end
  end
end
