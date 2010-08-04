
module Redcar
  class EditView
    class UpcaseTextCommand < Redcar::DocumentCommand
      
      def execute
        if doc.selection?
          doc.replace_selection {|text| text.upcase }
        else
          doc.replace_word_at_offset(doc.cursor_offset) {|text| text.upcase }
        end
      end
    end
  end
end
