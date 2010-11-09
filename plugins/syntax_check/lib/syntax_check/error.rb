module Redcar
  module SyntaxCheck
    class Error
      Type  = "syntax.error.type"
      Icon  = "compile-error"
      Color = [255, 32, 32]

      attr_accessor :line, :char, :message, :doc

      def initialize(doc, line, message, char=0)
        @doc       = doc
        @line      = line
        @message   = message
        @char      = char
      end

      def annotate
        edit_view = doc.edit_view
        edit_view.add_annotation_type(Type, Icon, Color)
        edit_view.add_annotation(Type, line, message, @char, doc.get_line(line).length)
      end
    end
  end
end
