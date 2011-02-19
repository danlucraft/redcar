module Redcar
  # A Redcar::Command class encapsulates a block of code, along with metadata
  # to describe in what ways it can be called, and how Redcar will treat the
  # command instances.
  #
  # Define commands by subclassing the Redcar::Command class.
  #
  # ## Examples
  #
  #     class CloseTab < Redcar::Command
  #       def self.keymaps
  #          Redcar::Keymap.build("main", :osx) do
  #            link "Cmd+W",  CloseTab
  #          end            
  #       def execute
  #         tab.close if tab
  #       end
  #     end
  #
  # ## Avoiding Memory Leaks (Command instance Lifecycle)
  #
  # When a command is activated, an instance of the Command class will be created.
  # Once the command has been run, the Command instance is put into the Command History,
  # which stores recent commands so they are accessible to e.g. Macros.
  #
  # This means that the command instance will hang around indefinitely, so it is 
  # easy to create a memory leak (it is not 'technically' a leak because the Command
  # will be collected eventually, just probably not soon enough.)
  #
  # For example, this command has a memory leak:
  #
  #     class MyCommand < Redcar::Command
  #       def execute
  #         @cache = create_outrageously_large_data_structure
  #         do_some_stuff_with_data_structure
  #       end
  #     end
  #
  # Because the History will store the MyCommand instance, the @cache object will 
  # be around for quite a while. Best to get rid of it:
  #
  #     class MyCommand < Redcar::Command
  #       def execute
  #         @cache = create_outrageously_large_data_structure
  #         do_some_stuff_with_data_structure
  #         @cache = nil
  #       end
  #     end
  class Command
    attr_accessor :error
    
    extend Redcar::Observable
    extend Redcar::Sensitive

    def self.inherited(klass)
      klass.send(:extend, Redcar::Sensitive)
      klass.sensitize(*sensitivity_names)
    end
    
    # Called by the Sensitive module when the active value of this changed
    def self.active_changed(value)
      notify_listeners(:active_changed, value)
    end
    
    def self.norecord
      @record = false
    end
    
    def self.record?
      @record == nil or @record
    end
    
    def environment(env)
      if env == nil
        remove_instance_variable(:@env) if @env
      else
        @env = env
      end
    end
    
    def run(opts = {})
      @executor = Executor.new(self, opts)
      s = Time.now
      result = @executor.execute
      remove_instance_variable(:@executor)
      Redcar.log.debug("command #{self.inspect} (#{Time.now - s})")
      result
    end
    
    def inspect
      "#<#{self.class.name}>"
    end
    
    private
    
    def env
      @env || {}
    end
    
    def win
      @win || env[:win]
    end
    
    def tab
      @tab || env[:tab]
    end
  end
end
