module Redcar
  class Grammar
    module Ruby

      def word
        /^(\w)+(\?|\!)?$/u
      end
    end
  end
end
