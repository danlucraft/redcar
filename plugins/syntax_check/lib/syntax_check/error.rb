module Redcar
  module SyntaxCheck
    class Error
      Type  = "syntax.error.type"
      Icon  = "compile-error"
      Color = [255, 32, 32]

      attr_accessor :line, :message, :doc

      def initialize(doc, line, message)
        @doc       = doc
        @line      = line
        @message   = message
      end

      def annotate
        edit_view = doc.edit_view
        edit_view.add_annotation_type(Type, Icon, Color)
        edit_view.add_annotation(Type, line, message, 0, doc.get_line(line).length)
      end
    end
  end
end
