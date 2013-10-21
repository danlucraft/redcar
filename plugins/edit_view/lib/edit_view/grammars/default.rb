module Redcar
  class Grammar
    class Default

      def self.instance
        @instance ||= new
      end

      def word
        /^\w+$/u
      end
    end
  end
end
