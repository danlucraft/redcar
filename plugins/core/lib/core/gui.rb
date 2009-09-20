
module Redcar
  class Gui
    class << self
      # All defined GUIs
      def all
        @all ||= []
      end
    end
    
    # Initialize a new named gui.
    #
    # @param [String] name for the gui
    def initialize(name)
      @controllers = Hash.new { |h,k| h[k] = [] }
      Gui.all << self
    end
    
    # Associates a model class and a controller class within this Gui.
    #
    # @param [Hash] model_class => controller_class
    def register_controller(options)
      options.each do |model_class, controller_class|
        @controllers[model_class] << controller_class
      end
    end
    
    # Set the event loop object for this gui.
    #
    # @param [Object] the event loop, which must implement
    #        start and stop methods
    def register_event_loop(event_loop)
      @event_loop = event_loop
    end
    
    # Starts the event loop for this gui.
    def start
      @event_loop.start
    end
    
    # Stops the event loop for this gui.
    def stop
      @event_loop.stop
    end
    
    def controller_for(model)
      @controllers[model.class].first
    end
  end
end