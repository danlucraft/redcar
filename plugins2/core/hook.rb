module Redcar
  # The Hook module allows plugins to register hooks that other
  # plugins can attach arbitrary code blocks to. 
  #
  # === Examples
  #
  # Registering a Hook (equivalent):
  #   Hook.register("MyHook")
  #   Hook.register(:MyHook)
  # 
  # Attaching code to a Hook:
  #   Hook.attach :MyHook do
  #     puts "code to run when MyHook is triggered"
  #   end
  #
  # Triggering a hook:
  #   Hook.trigger :MyHook
  #
  # === Before and After Hooks
  #
  # When a hook is registered, two extra hooks are automatically
  # created:
  #   before_MyHook
  #   after_MyHook
  #
  # And you may attach to them:
  #   Hook.attach "after_MyHook" do
  #     puts "code to run after MyHook"
  #   end
  #   Hook.attach "before_MyHook" do
  #     puts "code to run before MyHook"
  #   end
  #
  # If you trigger MyHook as above then MyHook, before_MyHook and 
  # after_MyHook will all be triggered simultaneously when MyHook 
  # is triggered.
  #
  # But you may instead trigger a hook with a block:
  #   Hook.trigger :MyHook do
  #     puts "stuff that happens"
  #   end
  #
  # And if so then before_MyHook will be triggered before the block
  # and after_MyHook and MyHook will be triggered after the block. This
  # allows you to attach work to be done before an event or after it.
  #
  # === Triggering with Objects
  # 
  # A Hook may pass an object to it's blocks when it is triggered,
  # and the block can then optionally make use of that object:
  #   Hook.attach :NewTab do |new_tab|
  #     puts "do some stuff with the new tab"
  #   end
  #   Hook.trigger(:NewTab, new_tab)
  # 
  #
  # Actually the Hook may pass in any number of objects:
  #   Hook.attach :MyHook do |a, b, c|
  #     puts "an embarrassment of riches"
  #   end
  #   Hook.trigger(:MyHook, this, that, the_other_thing)
  module Hook
    extend FreeBASE::StandardPlugin
    
    # Returns an array of all hook names in the system (as Strings)
    def self.names
      bus("/redcar/hooks/").children.map {|c| c.name}
    end
    
    # Registers a hook.
    def self.register(name)
      if exists? name
        raise "Hook #{name} already registered."
      end
      bus("/redcar/hooks/#{name}")
      bus("/redcar/hooks/before_#{name}")
      bus("/redcar/hooks/after_#{name}")
    end
    
    # Unregisters a hook.
    def self.unregister(name)
      if exists? name
        bus("/redcar/hooks/#{name}").prune
      end
    end

    # True if hook with name name exists
    def self.exists?(name)
      names.include? name.to_s
    end
      
    # Attach a block to be called when any of the hooks in hooks are 
    # called.
    def self.attach(*hooks, &block)
      hooks.each do |hook|
        hook = hook.to_s
        raise "No such hook: #{hook}" unless names.include? hook
        hooks = (bus["/redcar/hooks/#{hook}"].data ||= [])
        hooks << {:block => block, :caller => caller_file(caller, [__FILE__])}
      end
    end
    
    # Remove all the hooks that the calling file has set. 
    def self.clear_my_hooks(who=nil)
      who = caller_file(caller, [__FILE__]) unless who
      bus('/redcar/hooks').each_slot do |slot|
        slot.data = (slot.data||[]).reject do |hk| 
          hk[:caller] =~ Regexp.new(Regexp.escape(who)+"$")
        end
      end
    end
    
    # Remove all hooks set by the given plugin (which should be a 
    # class constant eg. Com::RedcarIDE::Scripting)
    def self.clear_plugin_hooks(plugin)
      module_to_plugin = {}
      bus("/plugins/").children.each do |slot|
        mod = slot.manager.plugin_configuration.startup_module
        module_to_plugin[mod] = slot.name
      end
      plugin_name = module_to_plugin[plugin.to_s]
      files = (bus("/plugins/#{plugin_name}/files/plugin").data || [])
      files += (bus("/plugins/#{plugin_name}/files/test").data || [])
      files.each do |file|
        clear_my_hooks(file)
      end
    end
    
    def self.is_before_or_after_hook?(name) # :nodoc:
      name.to_s[0..6] == "before_" or name.to_s[0..5] == "after_"
    end
    
    # Trigger a hook. Has an optional object (to pass into the hooked
    # blocks) and an optional block.
    def self.trigger(name, *objects)
      unless exists? name
        raise "Trying to trigger unknown hook: #{name}"
      end
      unless is_before_or_after_hook? name
        call_blocks("before_"+name.to_s, *objects)
      end
      
      yield if block_given?
      
      call_blocks(name, *objects)
      unless is_before_or_after_hook? name
        call_blocks("after_"+name.to_s, *objects)
      end
    end
      
    def self.call_blocks(name, *objects) #:nodoc:
      (bus["/redcar/hooks/#{name}"].data||[]).each do |hash|
        hash[:block].call(*objects)
      end
    end
  end
end
