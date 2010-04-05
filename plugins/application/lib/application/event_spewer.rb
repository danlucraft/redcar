
module Redcar
  class Application
    class EventSpewer
      def initialize
        @within = {}
      end
      
      def ignore?(name, *args)
        !!@within[[name, args]]
      end
      
      def ignore(name, *args)
        @within[[name, args]] = true
        begin
          yield
        ensure
          @within.delete([name, args])
        end
      end
      
      def create(name, *args)
        Redcar.plugin_manager.loaded_plugins.detect do |plugin|
          if plugin.object.respond_to?(:application_event_handler)
            handler = plugin.object.application_event_handler
            if handler.respond_to?(name)
              handler.send(name, *args)
            end
          end
        end
      end
    end
  end
end