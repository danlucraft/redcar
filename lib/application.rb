
module Redcar
  @@gconf_client = GConf::Client.default
  
  def self.[]=(key, val)
    @@gconf_client["/apps/redcar/"+key] = val
  end
  
  def self.[](key)
    @@gconf_client["/apps/redcar/"+key]
  end
    
  # Closes the entire Redcar application, after 
  # calling the Redcar event :quit
  def self.quit
    Redcar.event :quit
    Gtk.main_quit
  end
  
  class << self
    attr_accessor :windows, :panes, :edit_pane, :window_controller, :output_style
  end
  
  # False if redcar echoes events to STDOUT, true if it is silent.
  def self.silent?
    output_style == :silent
  end
  
  # Returns the filename of the caller of the caller of this method.
  def self.caller_file(callstack)
    callstack.each do |callline|
      val = callline.split(":").first.split("/")[-2..-1].join("/")
      return val unless val.include? "application.rb"
    end
  end
  
  # Hook a block to be called when any of the events in @events@ are 
  # called.
  def self.hook(*events, &block)
    events.each do |event|
      @@hooks ||= {}
      @@hooks[event] ||= []
      @@hooks[event] << {:block => block, :caller => caller_file(caller)}
    end
  end
  
  # Remove all the hooks that the calling file has set.
  def self.clear_hooks(who=nil)
    who = caller_file(caller) unless who
    @@hooks.each do |key, eventlist|
      @@hooks[key] = eventlist.select {|hk| hk[:caller] != who}
    end
  end
  
  def self.is_before_or_after_event?(name) # :nodoc:
    name.to_s[0..6] == "before_" or name.to_s[0..5] == "after_"
  end
  
  # Call an event. Has an optional object (to pass into the hooked
  # blocks) and an optional block.
  def self.event(name, object=nil)
    unless is_before_or_after_event? name
      before_name = ("before_" + name.to_s).intern
      self.event(before_name, object)
    end

    yield if block_given?

    @@hooks ||= {}
    hooks = @@hooks[name] || []
    any = (hooks.length > 0 ? ":" : ".")
    if (!name.to_s.include? "keystroke" and 
        !is_before_or_after_event? name) or 
        hooks.length > 0
        puts " #{name}, #{hooks.length} hooks"+any unless Redcar.silent?
        hooks.each {|hook| puts "   - #{hook[:caller]}" unless Redcar.silent? }
    end
    hooks.each do |hook|
      val = hook[:block].call(object)
    end
    unless is_before_or_after_event? name
      after_name = ("after_" + name.to_s).intern
      self.event(after_name, object)
    end
  end
end
