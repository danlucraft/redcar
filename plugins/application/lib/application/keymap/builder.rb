
module Redcar
  class Keymap
    class Builder
      attr_reader :keymap

      def initialize(name, platforms, &block)
        @keymap = Keymap.new(name, platforms)
        instance_eval(&block)
      end
      
      private
      
      def link(key, command)
        @keymap.link(key, command)
      end
    end
  end
end