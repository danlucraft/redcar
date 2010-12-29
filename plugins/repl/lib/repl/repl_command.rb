
module Redcar
  class REPL
    class ReplCommand

      attr_reader :title,:description,:regex

      def initialize(title,regex,description,&block)
        @title = title
        @regex = regex
        @description  = description
        @block = block
      end

      def call(match_data)
        @block.call match_data
      end
    end
  end
end