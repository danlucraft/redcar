
module Redcar
  class Application
    class EventSpewer
      attr_accessor :within
      
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
        Redcar.plugin_manager.objects_implementing(:application_event_handler).each do |object|
          handler = object.application_event_handler
          handler.send(name, *args) if handler.respond_to?(name)
        end
      end
    end
  end
end