
module Redcar
  class EditView
    class UpcaseTextCommand < Redcar::DocumentCommand
      
      def execute
        doc.replace_selection {|text| text.upcase }
      end
    end
  end
end
