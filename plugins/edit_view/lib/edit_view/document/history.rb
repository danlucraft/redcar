
module Redcar
  class Document
    class History < Array
      attr_reader :max
      
      def initialize(max)
        @max         = max
        @subscribers = []
      end
      
      # Record an action in the History
      def record(action)
        self << action
        notify_subscribers(action)
        truncate
      end
      
      def subscribe(&block)
        @subscribers << block
        block
      end
      
      def unsubscribe(block)
        @subscribers.delete(block)
      end
      
      private
      
      def notify_subscribers(action)
        @subscribers.each {|subscriber| subscriber.call(action)}
      end
      
      def truncate #:nodoc:
        if length > @max + 100
          self[0..(length - @max)] = nil
        end
      end
    end
  end
end
