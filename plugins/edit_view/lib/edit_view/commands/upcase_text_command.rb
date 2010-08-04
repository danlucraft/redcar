
module Redcar
  class EditView
    class UpcaseTextCommand < Redcar::DocumentCommand
      
      def execute
        selection_range = doc.selection_range
        start_offset    = selection_range.first
        end_offset      = selection_range.last
        selected_text   = doc.selected_text
        new_text        = selected_text.upcase
        doc.replace(start_offset, end_offset - start_offset, new_text)
      end
    end
  end
end
