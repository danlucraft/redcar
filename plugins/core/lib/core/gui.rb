
module Redcar
  module Gui
    class << self
      def all
        @all ||= []
      end
    end
    
    def initialize(name)
      @views = Hash.new { |h,k| h[k] = [] }
      Gui.all << self
    end
    
    def register_view(model, view)
      @views[model] << view
    end
    
    def register_event_loop(event_loop)
      @event_loop = event_loop
    end
    
    def start
      event_loop.start
    end
    
    def stop
      event_loop.stop
    end
  end
end