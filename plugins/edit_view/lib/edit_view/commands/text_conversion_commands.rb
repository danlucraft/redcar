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
    
    class OppositeCaseTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor do |text|
          text.tr('a-zA-Z', 'A-Za-z')
        end
      end
    end

    class CamelCaseTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor(&:camelize)
      end
    end
    
    class UnderscoreTextCommand < TextConversionCommand
      def execute
        replace_selection_or_word_at_cursor(&:lower_case_underscore)
      end
    end
    
    # Blantantly taken from the "Toggle camelCase / snake_case / PascalCase" Command
    # in TextMate's Source bundle written by Allan Odgaard.
    class CamelSnakePascalRotateTextCommand < TextConversionCommand
      # HotFlamingCats -> hot_flaming_cats
      def pascalcase_to_snakecase(word)
        word.gsub(/\B([A-Z])(?=[a-z0-9])|([a-z0-9])([A-Z])/, '\2_\+').downcase
      end
      
      # hot_flaming_cats -> hotFlamingCats
      def snakecase_to_camelcase(word)
        word.gsub(/_([^_]+)/) { $1.capitalize }
      end
      
      # hotFlamingCats -> HotFlamingCats
      def camelcase_to_pascalcase(word)
        word.gsub(/^\w{1}/) {|c| c.upcase}
      end      

      def execute
        replace_selection_or_word_at_cursor do |word|
          is_pascal = word.match(/^[A-Z]{1}/) ? true : false
          is_snake = word.match(/_/) ? true : false

          if is_pascal then
            pascalcase_to_snakecase(word)
          elsif is_snake then
  	        snakecase_to_camelcase(word)
          else
            camelcase_to_pascalcase(word) 
          end
        end
      end
    end
  end
end
