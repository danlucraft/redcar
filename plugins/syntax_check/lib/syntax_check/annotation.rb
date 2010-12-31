module Redcar
  module SyntaxCheck
    class Annotation

      def self.type
        "syntax.annotation.type"
      end

      def icon
        "application--exclamation"
      end

      def color
        [255, 255, 255]
      end

      attr_accessor :line, :char, :message, :doc

      def initialize(doc, line, message, char=0)
        @doc       = doc
        @line      = line
        @message   = message
        @char      = char
      end

      def annotate
        edit_view = doc.edit_view
        edit_view.add_annotation_type(self.class.type, icon, color)
        edit_view.add_annotation(self.class.type, line, message, @char, doc.get_line(line).length-@char)
      end
    end

    class Error < Annotation
      def self.type
        "syntax.error.type"
      end

      def icon
        "compile-error"
      end

      def color
        [255, 32, 32]
      end
    end

    class Warning < Annotation
      def self.type
        "syntax.warning.type"
      end

      def icon
        "compile-warning"
      end

      def color
        [255, 194, 10]
      end
    end
  end
end