module Redcar
  class Grammar
    class Ruby

      def self.instance
        @instance ||= new
      end

      def word
        /^(\w)+(\?|\!)?$/u
      end
    end
  end
end
