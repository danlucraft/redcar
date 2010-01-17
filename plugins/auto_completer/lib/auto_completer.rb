
#require 'auto_completer/document_controller'

require 'auto_completer/word_iterator'
require 'auto_completer/word_list'

module Redcar
  class AutoCompleter
    WORD_CHARACTERS = /:|@|\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Auto Complete", AutoCompleteCommand
        end
      end
    end
    
    class AutoCompleteCommand < Redcar::EditTabCommand
      key "Escape"
      
      def execute
        iterator = WordIterator.new(doc, WORD_CHARACTERS)
        word_list = WordList.new
        
        word, left, right = touched_word
        p [word, left, right]
        
        iterator.each_word_with_offset(word) do |word, offset|
          distance = (offset - doc.cursor_offset).abs
          word_list.add_word(word, distance)
        end
        completion = word_list.completions[1]
        
        doc.insert(right, completion[word.length..-1])
        word_end_offset = right + completion.length
        doc.cursor_offset = word_end_offset
      end
      
      private
      
      # returns the word that is being touched by the cursor and an array 
      # containing [left, right] document offsets of the word.
      def touched_word
        line = doc.get_line(doc.cursor_line)
        left, right = word_range(line)
        word = doc.get_range(left, right - left)
        return nil if word.length == 0
        return word, left, right
      end
      
      private
      
      # returns the range that holds the current word (depending on WORD_CHARACTERS)
      def word_range(line)
        left = doc.cursor_line_offset - 1
        right = doc.cursor_line_offset
        left_range = 0
        right_range = 0
        offset = doc.cursor_offset
        
        until left == -1 || WORD_CHARACTERS !~ (line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until right == line.length || WORD_CHARACTERS !~ (line[right].chr)
          right += 1
          right_range += 1
        end
        return [offset+left_range, offset+right_range]
      end
    end
  end
end
