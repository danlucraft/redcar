
module Redcar
  # A Sensitivity represents an application state that can be true or false
  # For example, whether there is text selected, whether there are any
  # open edit tabs, whether there is a project open.
  #
  # The Commands use these sensitivities to determine whether they are 
  # active or not, so that their menu items can be greyed out in the menus
  # if they are inactive.
  #
  # The "whether there are any open edit tabs" sensitivity is defined like this:
  #
  #   Sensitivity.new(:open_edit_tab, Redcar.app, [:new_tab, :close_tab]) do
  #     # checks whether there are any open tabs
  #   end
  #
  # This says that this sensitivity is called :open_edit_tab, that the state
  # it represents ONLY changes when the application object issues events :new_tab or
  # close_tab (see Redcar::Observable for more on events).
  #
  # A new tab opening or a tab closing MAY change the state, but on the other
  # hand it may not, so the code in the block examines the application and
  # returns a boolean true or false.
  class Sensitivity
    include Redcar::Observable
    extend Redcar::Observable
    
    # All sensitivities
    def self.all
      @all ||= {}
    end
    
    def self.get(name)
      all[name] || raise("unknown Sensitivity:#{name}")
    end
    
    def self.event_name(sensitivity_name)
      :"sensitivity_#{sensitivity_name.to_s}"
    end
    
    def self.broadcast_sensitivity_change(sensitivity_name, active)
      notify_listeners(event_name(sensitivity_name), active)
    end
    
    attr_reader :name

    def initialize(name, observed_object, event_names, &block)
      Sensitivity.all[name] = self
      @name                 = name
      @observed_object      = observed_object
      @event_names          = event_names
      @boolean_finder       = block
      @active               = true
      connect_listeners
    end
    
    def active?
      @active
    end
    
    private
    
    def connect_listeners
      @event_names.each do |event_name|
        @observed_object.add_listener(event_name) do |args|
          before = @active
          @active = @boolean_finder.call(*args)
          if before != @active
            notify_listeners(:changed)
            Sensitivity.broadcast_sensitivity_change(@name, @active)
          end
        end
      end
    end
  end
end