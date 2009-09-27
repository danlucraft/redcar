
module Redcar
  class Gui
    class << self
      # All defined GUIs
      def all
        @all ||= []
      end
    end
    
    attr_reader :name
    
    # Initialize a new named gui.
    #
    # @param [String] name for the gui
    def initialize(name)
      @name = name
      Gui.all << self
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
    
    # Set the cucumber features runner for this gui.
    #
    # @param [Object] the feature runner, which must implement
    #         a run_features(args) method, where args is the cucumber
    #         arguments
    def register_features_runner(feature_runner)
      @feature_runner = feature_runner
    end
    
    # Run cucumber features
    #
    # @param [Array[String]] run cucumber features with these args
    def run_features(args)
      @feature_runner.run_features(args)
    end
  end
end