module Redcar
  module SyntaxCheck
    class RubySyntaxError < Error
      def initialize(doc, hash)
        file = File.basename(hash[:file])
        hash[:message] =~ /#{Regexp.escape(file)}:(\d+):(.*)/
        @doc              = doc
        @line             = $1.to_i - 1
        @message          = $2
      end
    end
  end
end
