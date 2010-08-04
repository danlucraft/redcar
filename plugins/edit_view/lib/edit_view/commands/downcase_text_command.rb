module Redcar
  class EditView
    class DowncaseTextCommand < Redcar::DocumentCommand
      
      def execute
        if doc.selection?
          doc.replace_selection {|text| text.downcase }
        else
          doc.replace_word_at_offset(doc.cursor_offset) {|text| text.downcase }
        end
      end
    end
  end
end
