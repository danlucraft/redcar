
module Redcar
  class Keymap
    class Builder
      attr_reader :keymap

      def initialize(name, platforms, &block)
        @keymap = Keymap.new(name, platforms)
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
      
      private
      
      def link(key, command)
        @keymap.link(key, command)
      end
    end
  end
end