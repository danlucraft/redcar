
module Redcar
  class Gui
    class << self
      def all
        @all ||= []
      end
    end
    
    # Initialize a new named gui.
    #
    # @param [String] name for the gui
    def initialize(name)
      @views = Hash.new { |h,k| h[k] = [] }
      Gui.all << self
    end
    
    # Associates a model and a view within this Gui.
    #
    # @param [Object] the Redcar model
    # @param [Object] the view for the model
    def register_view(model, view)
      @views[model] << view
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
      event_loop.start
    end
    
    # Stops the event loop for this gui.
    def stop
      event_loop.stop
    end
  end
end