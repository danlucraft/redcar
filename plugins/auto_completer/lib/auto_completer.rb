
module Redcar
  class ApplicationSWT
    class Menu
      def move(x, y)
      	@menu_bar.setLocation(x, y)
      end
    end
  end
end

require 'auto_completer/current_document_completion_source'
require 'auto_completer/document_controller'
require 'auto_completer/word_iterator'
require 'auto_completer/word_list'

module Redcar
  class AutoCompleter
    WORD_CHARACTERS = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def self.document_controller_types
      [AutoCompleter::DocumentController]
    end
    
    def self.autocompletion_source_types
      [AutoCompleter::CurrentDocumentCompletionSource]
    end
    
    def self.all_autocompletion_source_types
      result = []
      Redcar.plugin_manager.objects_implementing(:autocompletion_source_types).each do |object|
        result += object.autocompletion_source_types
      end
      result
    end
    
    class AutoCompleteCommand < Redcar::EditTabCommand
      
      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        controller.start_modification

        if controller.in_completion?
          doc.delete(doc.cursor_offset - controller.length_of_previous, controller.length_of_previous)
          prefix = controller.prefix
          left = controller.left
          right = controller.right
          word_list = controller.word_list
        else
          prefix, left, right = touched_prefix
          if prefix
            word_list = alternatives(prefix)
            controller.word_list = word_list
            controller.prefix    = prefix
            controller.left      = left
            controller.right     = right
          end
        end
        
        if prefix
          index = (controller.index || 0) + 1
          if word_list.completions.length == index
            index = 0
          end
          completion = word_list.completions[index]
          controller.index = index
          
          start_offset = right
          doc.insert(right, completion[prefix.length..-1])
          word_end_offset = right + completion.length - prefix.length
          doc.cursor_offset = word_end_offset
  
          controller.length_of_previous = completion.length - prefix.length
  
          controller.start_completion
        end
        controller.end_modification
      end
      
      private
      
      def alternatives(prefix)
        sources = AutoCompleter.all_autocompletion_source_types.map do |t| 
          t.new(doc, Project::Manager.focussed_project.path)
        end
        word_list = WordList.new
        sources.each do |source|
          if alts = source.alternatives(prefix)
            word_list.merge!(alts)
          end
        end
        word_list
      end
      
      # returns the prefix that is being touched by the cursor and an array 
      # containing [left, right] document offsets of the prefix.
      def touched_prefix
        line = doc.get_line(doc.cursor_line)
        left, right = word_range(line)
        prefix = doc.get_range(left, right - left)
        return nil if prefix.length == 0
        return prefix, left, right
      end
      
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
        
        return [offset+left_range, offset+right_range]
      end
    end
    
    class MenuAutoCompleterCommand < AutoCompleteCommand
    
      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        input_word = ""
        word_list = controller.word_list
        prefix, left, right = touched_prefix
        if prefix
          word_list = alternatives(prefix)
          controller.word_list = word_list
          controller.prefix    = prefix
          controller.left      = left
          controller.right     = right

  		    cur_doc = doc
        	builder = Menu::Builder.new do
        	  word_list.words.each do |current_word, word_distance|
        	  	item(current_word) do
        	  	  offset = cur_doc.cursor_offset - prefix.length
        	  	  text   = current_word[input_word.length..current_word.length]
        	  	  cur_doc.replace(offset, prefix.length, text)
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
end
