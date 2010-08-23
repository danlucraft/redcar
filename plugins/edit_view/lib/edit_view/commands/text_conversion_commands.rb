module Redcar
  class EditView
    # Subclass and implement a 'convert/1 method.'
    class TextConversionCommand < Redcar::DocumentCommand
      # Calls Document#replace_selection if something is highlighted
      # otherwise calls Document#replace_word_at_offset passing
      # Document#cursor_offset as the offset
      def execute(new_text=nil, &block)
        if doc.selection?
          doc.replace_selection(new_text, &method(:convert))
        else
          doc.replace_word_at_offset(doc.cursor_offset, new_text, &method(:convert))
        end
      end      
    end
    
    class UpcaseTextCommand < TextConversionCommand
      def convert(text)
        text.upcase
      end
    end
    
    class DowncaseTextCommand < TextConversionCommand      
      def convert(text)
        text.downcase
      end
    end
    
    class TitlizeTextCommand < TextConversionCommand
      def convert(text)
        text.gsub(/\b('?[a-z])/) { $1.capitalize }
      end
    end
    
    class OppositeCaseTextCommand < TextConversionCommand
      def convert(text)
        text.tr('a-zA-Z', 'A-Za-z')
      end
    end

    class CamelCaseTextCommand < TextConversionCommand
      def convert(text)
        text.camelize
      end
    end
    
    class UnderscoreTextCommand < TextConversionCommand
      def convert(text)
        text.lower_case_underscore
      end
    end
    
    # Ported from "Toggle camelCase / snake_case / PascalCase" Command
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

      def convert(word)
        is_pascal = word.match(/^[A-Z]{1}/) ? true : false
        is_snake = word.match(/_/) ? true : false

        if is_pascal
          pascalcase_to_snakecase(word)
        elsif is_snake
	        snakecase_to_camelcase(word)
        else
          camelcase_to_pascalcase(word) 
        end
      end
    end
  end
end
