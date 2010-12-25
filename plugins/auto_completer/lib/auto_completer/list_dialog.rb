
module Redcar
  class AutoCompleter
    class ListDialog < Redcar::ModelessListDialog

      def initialize(prefix,document)
        super()
        @prefix = prefix
        @doc = document
      end

      def selected
        if text = selection_value
          offset = @doc.cursor_offset - @prefix.length
          @doc.replace(offset, @prefix.length, text)
          close
        end
      end
    end
  end
end