module Redcar
  class EditView
    class TextConversionCommand < Redcar::DocumentCommand
      # Calls Document#replace_selection if something is highlighted
      # otherwise calls Document#replace_word_at_offset passing
      # Document#cursor_offset as the offset
      def replace_selection_or_word_at_cursor(new_text=nil, &block)
        if doc.selection?
          doc.replace_selection(new_text, &block)
        else
          doc.replace_word_at_offset(doc.cursor_offset, new_text, &block)
        end
      end      
    end
    
    class UpcaseTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor(&:upcase)
      end
    end
    
    class DowncaseTextCommand < TextConversionCommand      
      def execute
        replace_selection_or_word_at_cursor(&:downcase)
      end
    end
    
    class TitlizeTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor do |text|
          text.gsub(/\b('?[a-z])/) { $1.capitalize }
        end
      end
    end
    
    class OppositeCaseTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor do |text|
          text.tr('a-zA-Z', 'A-Za-z')
        end
      end
    end
  end
end
