

require 'auto_completer/document_controller'
require 'auto_completer/word_iterator'
require 'auto_completer/word_list'

module Redcar
  class AutoCompleter
    WORD_CHARACTERS = /:|@|\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def self.start
      Document.register_controller_type(AutoCompleter::DocumentController)
    end
    
    class AutoCompleteCommand < Redcar::EditTabCommand
      key "Ctrl+Escape"
      
      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        controller.start_modification

        if controller.in_completion?
          doc.delete(doc.cursor_offset - controller.length_of_previous, controller.length_of_previous)
        end

        iterator = WordIterator.new(doc, WORD_CHARACTERS)
        word_list = WordList.new
        
        word, left, right = touched_word

        if word
          iterator.each_word_with_offset(word) do |word, offset|
            distance = (offset - doc.cursor_offset).abs
            word_list.add_word(word, distance)
          end
  
          index = (controller.index || 0) + 1
          if word_list.completions.length == index
            index = 0
          end
          completion = word_list.completions[index]
          controller.index = index
          
          start_offset = right
          doc.insert(right, completion[word.length..-1])
          word_end_offset = right + completion.length
          doc.cursor_offset = word_end_offset
  
          controller.length_of_previous = completion.length - word.length
  
          controller.end_modification
          controller.start_completion
        end
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
        
#        until right == line.length || WORD_CHARACTERS !~ (line[right].chr)
#          right += 1
#          right_range += 1
#        end
        return [offset+left_range, offset+right_range]
      end
    end
  end
end
