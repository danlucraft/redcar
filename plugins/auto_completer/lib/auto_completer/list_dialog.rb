
module Redcar
  class AutoCompleter
    class ListDialog < Redcar::ModelessListDialog

      def initialize(prefix,document)
        super()
        @prefix = prefix
        @doc = document
      end

      def selected(index)
        if text = select(index)
          offset = @doc.cursor_offset - @prefix.length
          @doc.replace(offset, @prefix.length, text)
          close
        end
      end
    end
  end
end