
module Redcar
  class Keymap
    class Builder
      attr_reader :keymap

      def self.build(name=nil, &block)
        new(name, &block).keymap
      end
      
      def initialize(name=nil, &block)
        @keymap = Keymap.new(name)
        instance_eval(&block)
      end
      
      private
      
      def link(key, command)
        @keymap.link(key, command)
      end
    end
  end
end