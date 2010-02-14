module Redcar
  class ApplicationSWT
    class Menu
      def move(x, y)
      	@menu_bar.setLocation(x, y)
      end
    end
  end
end

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
      
      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        controller.start_modification

        if controller.in_completion?
          doc.delete(doc.cursor_offset - controller.length_of_previous, controller.length_of_previous)
          word = controller.word
          left = controller.left
          right = controller.right
          word_list = controller.word_list
        else
          word, left, right = touched_word
          if word
            iterator = WordIterator.new(doc, WORD_CHARACTERS)
            word_list = WordList.new
            iterator.each_word_with_offset(word) do |matching_word, offset|
              distance = (offset - doc.cursor_offset).abs
              word_list.add_word(matching_word, distance)
            end
            controller.word_list = word_list
            controller.word      = word
            controller.left      = left
            controller.right     = right
          end
        end
        if word
          index = (controller.index || 0) + 1
          if word_list.completions.length == index
            index = 0
          end
          completion = word_list.completions[index]
          controller.index = index
          
          start_offset = right
          doc.insert(right, completion[word.length..-1])
          word_end_offset = right + completion.length - word.length
          doc.cursor_offset = word_end_offset
  
          controller.length_of_previous = completion.length - word.length
  
          controller.start_completion
        end
        controller.end_modification
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
    
    class MenuAutoCompleterCommand < AutoCompleteCommand
    
      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        input_word = ""
        word_list = controller.word_list
        word, left, right = touched_word
        if word
          iterator = WordIterator.new(doc, WORD_CHARACTERS)
          word_list = WordList.new
          iterator.each_word_with_offset(word) do |matching_word, offset|
            distance = (offset - doc.cursor_offset).abs
            unless (distance - matching_word.length) == 0
	            word_list.add_word(matching_word, distance)
	          else
	          	input_word = matching_word
	          end
          end
          controller.word_list = word_list
          controller.word      = word
          controller.left      = left
          controller.right     = right
        end

		    cur_doc = doc
      	builder = Menu::Builder.new do
      	  word_list.words.each do |current_word, word_distance|
      	  	item(current_word) do
      	  		cur_doc.insert(cur_doc.cursor_offset, current_word[input_word.length..current_word.length])
      	  		cur_doc.cursor_offset = cur_doc.cursor_offset + current_word[input_word.length..current_word.length].length
      	  	end
      	  end
      	end
      	
      	window = Redcar.app.focussed_window
      	location = window.focussed_notebook.focussed_tab.controller.edit_view.mate_text.viewer.getTextWidget.getLocationAtOffset(window.focussed_notebook.focussed_tab.controller.edit_view.cursor_offset)
      	absolute_x = location.x
      	absolute_y = location.y
      	location = window.focussed_notebook.focussed_tab.controller.edit_view.mate_text.viewer.getTextWidget.toDisplay(0,0)
      	absolute_x += location.x
      	absolute_y += location.y
      	menu = ApplicationSWT::Menu.new(window.controller, builder.menu, nil, Swt::SWT::POP_UP)
        menu.move(absolute_x, absolute_y)
        menu.show
      end

    end
  end
end
